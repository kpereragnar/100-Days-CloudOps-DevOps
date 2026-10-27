# CloudOps / DevOps Journal

## Day 45 — 27 October 2026

**Challenges:** 100 Days of DevOps, 100 Days of Cloud, and **Terraform L1 Assessment**

> **Milestone:** Terraform L1 completed — 75% (pass). L2 unlocks tomorrow.

---

## 1. 100 Days of DevOps — `httpd` Container via Compose

**Task:** Create `httpd` container via `/opt/docker/docker-compose.yml`, host port 3003 → container 80, mount `/opt/finance` → `/usr/local/apache2/htdocs`.

**Compose file:**

```yaml
services:
  httpd:
    image: httpd:latest
    container_name: httpd
    ports: ["3003:80"]
    volumes:
      - /opt/finance:/usr/local/apache2/htdocs
```

**Commands:**

```bash
mkdir -p /opt/docker
# write compose file
cd /opt/docker && docker compose up -d
docker ps --filter "name=httpd"
docker port httpd                     # → 80/tcp -> 0.0.0.0:3003
docker inspect httpd --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
curl -sI http://localhost:3003 | head -1   # → 200 OK
```

### Key Learning

**`container_name` is not the service name.** Without it, Compose generates `docker-httpd-1` — the grader checks for literal `httpd`. The service name is just an internal label.

**Volume direction is host:container** — same orientation as `ports: "host:container"` and `docker cp <host> <container>:<path>`. Source first, always.

---

## 2. 100 Days of Cloud — Launch Template + ASG + ALB + Target Tracking

**Task:** LT with Nginx user data, ASG min 1 / desired 1 / max 2, ALB + target group, CPU target tracking at 50%.

**Commands used:**

```bash
# 1. User data (must be base64-encoded inline)
cat > /tmp/nginx-userdata.sh << 'EOF'
#!/bin/bash
yum update -y && yum install -y nginx
systemctl start nginx && systemctl enable nginx
EOF
USER_DATA_B64=$(base64 -w0 /tmp/nginx-userdata.sh)

# 2. Launch template
aws ec2 create-launch-template \
  --launch-template-name devops-launch-template \
  --launch-template-data "{
    \"ImageId\": \"$AMI\",
    \"InstanceType\": \"t2.micro\",
    \"SecurityGroupIds\": [\"$SG\"],
    \"UserData\": \"$USER_DATA_B64\"
  }"

# 3. Target group + ALB + listener
TG_ARN=$(aws elbv2 create-target-group \
  --name devops-tg --protocol HTTP --port 80 --vpc-id "$VPC" \
  --target-type instance --health-check-path / \
  --query "TargetGroups[0].TargetGroupArn" --output text)

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name devops-alb --subnets "$SUBNET_A" "$SUBNET_B" \
  --security-groups "$SG" --scheme internet-facing --type application \
  --query "LoadBalancers[0].LoadBalancerArn" --output text)

aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN"

# 4. ASG
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name devops-asg \
  --launch-template "LaunchTemplateName=devops-launch-template,Version=\$Latest" \
  --min-size 1 --max-size 2 --desired-capacity 1 \
  --vpc-zone-identifier "$SUBNET_A,$SUBNET_B" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 300
```

**The scaling policy — first attempt rejected:**

```bash
# ❌ FAILED — ScaleInCooldown not valid in EC2 ASG
{
  "TargetValue": 50.0,
  "PredefinedMetricSpecification": {"PredefinedMetricType": "ASGAverageCPUUtilization"},
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 300
}

# ✅ CORRECTED
cat > /tmp/cpu-scaling-policy.json << 'EOF'
{
  "TargetValue": 50.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ASGAverageCPUUtilization"
  }
}
EOF

aws autoscaling put-scaling-policy \
  --auto-scaling-group-name devops-asg \
  --policy-name devops-cpu50-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration file:///tmp/cpu-scaling-policy.json
```

**Verified:**

```bash
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
  --query "TargetHealthDescriptions[].TargetHealth.State" --output text   # → healthy
curl -sI "http://$ALB_DNS" | head -1                                       # → 200 OK
```

### Key Learning

**`ScaleInCooldown`/`ScaleOutCooldown` are for Application Auto Scaling, not EC2 ASG.** Same shape family, different API — exact repeat of Day 41's `--tag-specifications` vs `--tags` split.

**`--health-check-type ELB` must be explicit** — default is EC2 status checks, so a running-but-Nginx-broken instance would never be replaced.

**`UserData` must be base64-encoded inline** — `base64 -w0` (no wrapping). Plain shell script boots as garbage silently.

---

## 3. Terraform L1 Assessment — 75%

**10 questions · 105 of 110 minutes · 60% pass threshold**

| Q | Task | Status |
|---|---|---|
| Q1 | EC2 `nautilus-ec2-t1q2` + key pair | ✅ |
| Q2 | Key pair `nautilus-kp-t1q1` at `/home/bob` | ⚠️ Path trap |
| Q3 | IAM policy `iampolicy_jim_t2q4` with `KKE_iampolicy` | ✅ |
| Q4 | IAM user `iamuser_jim_t2q1` | ✅ |
| Q5 | DynamoDB `nautilus-users-t3q1` | ✅ |
| Q6 | SNS `nautilus-notifications-t3q4` | ✅ |
| Q7 | Public S3 via ACL `t4q2` | ⚠️ ACL chain |
| Q8 | Private S3 `t4q1` | ✅ |
| Q9 | VPC any CIDR `t5q1` | ✅ |
| Q10 | VPC `192.168.0.0/24` `t5q2` | ⚠️ CIDR precision |

**Representative patterns used:**

```hcl
# Q5 DynamoDB — hash_key + attribute must match
resource "aws_dynamodb_table" "t" {
  name         = "nautilus-users-t3q1"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "nautilus_id_t3q1"
  attribute { name = "nautilus_id_t3q1"; type = "S" }
}

# Q3 IAM policy — variable + jsonencode
resource "aws_iam_policy" "p" {
  name   = var.KKE_iampolicy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["s3:GetObject"], Resource = "*" }]
  })
}

# Q8 Private S3 — all four blocks true
resource "aws_s3_bucket_public_access_block" "b" {
  bucket                  = aws_s3_bucket.b.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Q9/Q10 VPC — inline (no variable required)
resource "aws_vpc" "v" {
  cidr_block = "192.168.0.0/24"    # Q10 (prescribed)
  tags       = { Name = "nautilus-vpc-t5q2" }
}
```

**Verification commands:**

```bash
terraform plan           # read the resolved `name =`, `cidr_block =` lines
terraform apply -auto-approve
aws dynamodb describe-table --table-name nautilus-users-t3q1
aws iam get-policy --policy-arn arn:aws:iam::<acct>:policy/iampolicy_jim_t2q4
aws s3api get-public-access-block --bucket nautilus-s3-330334356-t4q1
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=nautilus-vpc-t5q2"
```

### Key Learning

**The 105 minutes was the loop, not the knowledge.** Ten single-resource blocks. Each required write → plan → read error → edit → re-plan. **The assessment measures iteration speed, not memorization.**

**The three misses and their root causes:**

- **Q2** — `${path.module}` resolves to `/home/bob/terraform/t1q1`, not `/home/bob`. Same relative-vs-absolute trap as Day 41's `fileb://root/x` vs `fileb:///root/x`.
- **Q7** — Public ACL requires four resources in order: bucket + ownership controls (`BucketOwnerPreferred`) + public access block (all four `false`) + ACL with `depends_on`. Same `AccessControlListNotSupported` from Day 39.
- **Q10** — CIDR `192.168.0.0/24` was prescribed; default `/16` habit fails. Same value-precision lesson as Day 44's `iampolciy` typo.

**The three misses are the same three error classes the journal has documented all week:** path, dependency order, value precision.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| Terraform L1 | 27 Oct | ✅ **75% pass** |
| Terraform L2 start | 28 Oct | Tomorrow |
| K8 L1 | 7 Nov | On track |
| K8 L2 + Day 67 | 18–19 Nov | On track |
| 100 Days Day 100 | 22 Dec | On track |
| Projects | 22 Nov | On track |

---

## Key Takeaways

- 🐳 **`container_name` ≠ service name.** Grader checks `httpd`, not `docker-httpd-1`.
- 🐳 **Volume direction host:container** — same as `ports: "host:container"` and `docker cp`.
- ☁️ **`ScaleInCooldown` is Application Auto Scaling, not EC2 ASG.** Shape families differ per API.
- ☁️ **`--health-check-type ELB` must be explicit** — otherwise failed HTTP checks don't replace instances.
- ☁️ **`UserData` must be base64-encoded inline** — `base64 -w0`, plain script boots silently broken.
- 🔧 **Terraform L1: 75%, 105/110 min.** Time went to the write→plan→edit loop, which is the actual skill.
- 🔧 **Three misses: path trap, ACL chain, CIDR precision.** Same error classes as the whole week, under time pressure.

---

**Overall: 🟢 Day 45/100 — Completed · Terraform L1 Certified**

> **Realization:** Terraform L1 is a **speed-with-shape test**, not a knowledge test. Ten single-resource questions took 105 minutes because the loop — write, plan, read, edit, re-plan — ran ten times. The 25% I missed was the three shapes I hadn't internalized: the `${path.module}` trap, the ACL dependency chain, the CIDR precision. **Same three error classes the journal has been documenting all week.** The assessment didn't ask new questions — it asked the journal's questions under time pressure. **L2 is those three shapes with more moving parts.** The review list for week one of L2 is Q2, Q7, and Q10 — not to score higher, but to catch them on the first plan instead of the third.
