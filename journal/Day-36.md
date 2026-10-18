# CloudOps / DevOps Journal

## Day 36 — 18 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Run a Named Nginx Container Using the Alpine Tag

I was tasked with running a Docker container from the `nginx` image using the `alpine` tag, giving the container a specific name.

### What I Did

```bash
docker run -d --name <container-name> nginx:alpine
```

Verified:

```bash
docker ps
docker logs <container-name>
```

### Key Learning

**This was the easiest task in the entire challenge so far.** Not because the command is trivial — but because Docker L1, L2, and L3 had already made every part of it familiar:

- `docker run` — covered in L1
- `-d` (detached mode) — covered in L1
- `--name` flag — covered in L2
- `nginx:alpine` tag syntax — covered in L2
- `docker ps` / `docker logs` — covered in L1

**The pattern that emerged:** when a foundation certification is complete, the daily tasks built on top of it become almost automatic. The learning isn't in the command anymore — it's in recognizing that the command is familiar.

**A note on the `alpine` tag:** `nginx:alpine` is a lightweight version of the official Nginx image. It uses Alpine Linux as the base instead of Debian, which drops the image size from ~140MB to ~40MB. Same Nginx, smaller footprint. The trade-off is that Alpine uses `musl libc` instead of `glibc`, which occasionally causes compatibility issues with certain binaries — but for a basic web server, it's the standard choice.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: EC2 + Nginx + Application Load Balancer + Target Group

I was tasked with:

1. Create a security group `nautilus-sg` that opens port 80 **for the default security group** (which is attached to the ALB)
2. Attach `nautilus-sg` to the EC2 instance
3. Launch an EC2 instance `nautilus-ec2` with Ubuntu AMI and a user-data script that installs and starts Nginx
4. Create an ALB `nautilus-alb` with the default SG attached
5. Create a target group `nautilus-tg`
6. Route ALB port 80 traffic to the EC2 instance's port 80
7. Ensure the Nginx server is accessible via the ALB DNS name

### What I Did

**Step 1 — Created the security group for the EC2:**

```bash
NAUTILUS_SG=$(aws ec2 create-security-group \
  --group-name nautilus-sg \
  --description "Allow HTTP from ALB" \
  --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$NAUTILUS_SG" \
  --protocol tcp --port 80 --source-group "$DEFAULT_SG"
```

**Step 2 — Wrote the user-data script:**

```bash
cat > /tmp/userdata.sh << 'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
```

**Step 3 — Launched the EC2 instance:**

```bash
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t3.micro \
  --security-group-ids "$NAUTILUS_SG" \
  --user-data file:///tmp/userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nautilus-ec2}]' \
  --query "Instances[0].InstanceId" --output text)
```

**Step 4 — Created the target group:**

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name nautilus-tg \
  --protocol HTTP --port 80 \
  --vpc-id "$DEFAULT_VPC" \
  --target-type instance \
  --query "TargetGroups[0].TargetGroupArn" --output text)

aws elbv2 register-targets \
  --target-group-arn "$TG_ARN" \
  --targets Id="$INSTANCE_ID",Port=80
```

**Step 5 — Created the ALB (first attempt):**

```bash
aws elbv2 create-load-balancer \
  --name nautilus-alb \
  --subnets subnet-0ba34f17cf9dcba34 subnet-0bcb07b99457fd1a9 \
  --security-groups "$DEFAULT_SG" \
  --type application
```

**Step 6 — Created the listener:**

```bash
aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"
```

**Step 7 — Waited for target health:**

```bash
aws elbv2 wait target-in-service \
  --target-group-arn "$TG_ARN" \
  --targets Id="$INSTANCE_ID",Port=80
```

This hung. **The wait command was the first sign something was wrong.**

### Issues I Faced and How I Fixed Them

**Issue 1 — `target-in-service` wait hung for 5+ minutes**

My instinct was to wait longer. That was wrong. The `wait` command has **no timeout by default** — it will hang forever if the target never becomes healthy.

**Fix:** Ctrl+C, then run the diagnostic command instead:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query "TargetHealthDescriptions[0].TargetHealth" --output json
```

Output:

```json
{
    "State": "unused",
    "Reason": "Target.NotInUse",
    "Description": "Target is in an Availability Zone that is not enabled for the load balancer"
}
```

**This single output diagnosed the entire problem.** The `wait` command was hiding it.

**Issue 2 — EC2 was in `us-east-1b`, ALB was in `us-east-1a` and `us-east-1c`**

The reason code `Target.NotInUse` told me the root cause: **an ALB can only route traffic to targets that live in one of its own AZs.** The ALB is a distributed resource — when you give it two subnets, it spins up one node per AZ and nothing more. The EC2 in `1b` was invisible to the ALB in `1a` and `1c`.

**Fix attempt 1 — `set-subnets` to add the EC2's subnet to the ALB:**

```bash
aws elbv2 set-subnets \
  --load-balancer-arn "$ALB_ARN" \
  --subnets $CURRENT_SUBNETS "$EC2_SUBNET"
```

Failed with:

```
AccessDenied: User is not authorized to perform: elasticloadbalancing:SetSubnets
```

**Root cause:** The lab's IAM policy allows creating an ALB but not modifying its subnets. `SetSubnets` is a separate permission that's explicitly denied.

**Fix attempt 2 — delete and recreate the ALB with the correct subnets:**

```bash
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN"
sleep 45

NEW_ALB_ARN=$(aws elbv2 create-load-balancer \
  --name nautilus-alb \
  --subnets subnet-04e6bd5718712b45d subnet-0ba34f17cf9dcba34 \
  --security-groups "$DEFAULT_SG" \
  --type application \
  --query "LoadBalancers[0].LoadBalancerArn" --output text)

aws elbv2 create-listener \
  --load-balancer-arn "$NEW_ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"
```

This worked — the new ALB included the EC2's subnet (`1b`) plus one already-valid subnet (`1a`).

**Issue 3 — Target stuck in `initial` state**

After recreating the ALB, the target health check returned:

```
initial
```

**What `initial` means:** the ALB found the target and is actively running its first health checks. It hasn't decided yet. This state lasts 30–90 seconds (2 successful checks × 30-second interval minimum).

**Fix:** Wait 60 seconds, check again. The state transitions to `healthy` when the ALB gets two 200 responses in a row from Nginx on port 80.

### Key Learning

**The ALB is a distributed resource, not a single machine.**

When you create an ALB with:

```bash
--subnets subnet-A subnet-B
```

You're saying "the ALB exists only in the AZs of those subnets, and nowhere else." Anything in a different AZ is invisible. The `Target.NotInUse` reason code is telling you precisely this — not "the target isn't registered" (which is what most people assume), but "the ALB has no node in your instance's AZ to reach it."

**The preemptive rule for next time:** before creating the ALB, always check the EC2's AZ first, then pick subnets that include it.

```bash
EC2_AZ=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text)

SUBNET_SAME_AZ=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SubnetId" --output text)

SUBNET_OTHER_AZ=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC" \
  --query "Subnets[?AvailabilityZone!='$EC2_AZ'] | [0].SubnetId" --output text)
```

Then create the ALB with those two subnets. This guarantees the EC2's AZ is included from the start.

**The `wait` command is not a debugging tool.** It hides the reason code that would tell you what's wrong. `describe-target-health` is the actual debugging tool — always run it first when a target isn't healthy.

**The lab's IAM policy is deliberately narrow.** You can create resources but not always modify them. This forces you to get the creation right the first time — a habit that carries into production. `SetSubnets` was denied not because it's a bad operation but because the lab is designed to prevent "fix it after the fact" patterns.

**Security group chaining is the pattern being tested.** `nautilus-sg` on the EC2 must allow port 80 from the **default SG's ID**, not from `0.0.0.0/0`. That way the EC2 is only reachable through the ALB — never directly from the internet. The ALB is the only public entry point.

**The full traffic chain, one more time:**

```
Browser (Internet)
    │
    ▼  port 80 allowed by
[default SG] ←─ on ALB (nautilus-alb)
    │
    ▼  port 80 allowed by
[nautilus-sg] ←─ on EC2 (nautilus-ec2), source = default SG
    │
    ▼
  Nginx on EC2 (port 80)
```

Break any link and the ALB returns `503 Service Unavailable`, or the target stays `unhealthy`, or you get `Target.NotInUse`. Each failure mode points at a specific link.

**Three diagnostic checks, in order:**

| Check | Command | What "success" looks like |
|---|---|---|
| **Target health** | `aws elbv2 describe-target-health --target-group-arn $TG_ARN` | `State: healthy` |
| **ALB state** | `aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN` | `State.Code: active` |
| **Nginx on EC2** | `curl localhost` (via Instance Connect) | Nginx welcome HTML |

If the target is `unhealthy`, the reason code is either:

| Reason | Cause |
|---|---|
| `Target.Timeout` | SG blocking — `nautilus-sg` doesn't allow default SG on port 80 |
| `Target.FailedHealthChecks` | Nginx not running, or not listening on 80 |
| `Target.ResponseCodeMismatch` | Nginx returns non-200 (e.g., 301 redirect) |
| `Target.NotInUse` | AZ mismatch — instance in an AZ the ALB doesn't cover |

Each reason points at a different link in the chain. Read it, fix that link, retry.

---

## 3. Personal Tasks — Terraform

### Task 1: CloudFormation Stack

Created a CloudFormation stack named `nautilus-stack` containing an S3 bucket with versioning enabled.

```hcl
resource "aws_cloudformation_stack" "nautilus_stack" {
  name = "nautilus-stack"

  template_body = <<STACK
Resources:
  NautilusBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: nautilus-bucket-633530432
      VersioningConfiguration:
        Status: Enabled
STACK

  tags = {
    Name = "nautilus-stack"
  }
}
```

**Learning:** Terraform can act as a wrapper around CloudFormation. The `template_body` argument takes the CloudFormation template as a heredoc string. This is useful when a resource only exists as a CloudFormation type (custom resources, or legacy infrastructure) — Terraform manages the stack lifecycle, CloudFormation manages the resources inside.

**The split:** `create-stack` alone doesn't suffice when IAM roles are involved — you'd need `aws_cloudformation_stack` + `aws_iam_role` + `aws_iam_role_policy_attachment`. That's in section 6.5 of the sheet (the splits table).

### Task 2: OpenSearch Domain

Created an OpenSearch domain named `nautilus-es`.

**First attempt — minimal:**

```hcl
resource "aws_opensearch_domain" "nautilus_es" {
  domain_name    = "nautilus-es"
  engine_version = "OpenSearch"
}
```

**Problems:**

1. `engine_version = "OpenSearch"` is not a valid version string. It must be a specific version like `"OpenSearch_2.11"`.
2. `cluster_config` and `ebs_options` are **required** on real AWS — the API rejects the request without instance type and EBS settings.

**The plan output confirmed this:** `cluster_config (known after apply)` and `ebs_options (known after apply)` — Terraform didn't know the values because I didn't specify them. That's a hint that they're expected.

**Corrected config:**

```hcl
resource "aws_opensearch_domain" "nautilus_es" {
  domain_name    = "nautilus-es"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
}
```

**Learning:**

- **`engine_version` must be a specific version string.** `"OpenSearch"` alone is a family name, not a version. The valid format is `"OpenSearch_X.Y"`.
- **`cluster_config` and `ebs_options` are required.** The Terraform registry docs mark them as optional, but the AWS API rejects the request without them. LocalStack sometimes accepts the minimal config; real AWS does not.
- **`(known after apply)` in the plan is a hint.** When a required block shows this instead of a specific value, it means Terraform is going to compute it — which means you didn't set it. If the resource requires it, the apply will fail or hang.
- **OpenSearch provisioning takes 10–15 minutes.** The `Still creating...` output is normal. Do not Ctrl+C — that leaves the domain in a broken state.
- **The `describe-domain` check matters.** After `apply` completes, verify `Processing: false` and `DomainName: nautilus-es`. If `Processing` stays `true` for over 20 minutes, the domain may have failed to provision.

---

## Key Takeaways

- 🐳 **Foundation certifications turn tasks into muscle memory.** The Docker task took 30 seconds because Docker L1, L2, L3 had already covered every part of it.
- ⚖️ **The ALB is a distributed resource, not a single machine.** It only exists in the AZs of the subnets you give it. Targets outside those AZs are invisible — even if they're registered.
- 🔍 **`Target.NotInUse` means AZ mismatch, not "not registered."** Most people read it as the latter and waste time re-registering. Read the reason code carefully.
- ⏳ **`wait target-in-service` has no timeout.** It hangs forever if the target never becomes healthy. Use `describe-target-health` to see the reason instead.
- 🔒 **The lab's IAM policy is deliberately narrow.** `SetSubnets` is denied — you can create but not modify. Get the creation right the first time.
- 🛡️ **Security group chaining is the pattern:** the EC2's SG allows port 80 **from the default SG's ID**, not from the internet. The EC2 is only reachable through the ALB.
- 📋 **CloudFormation-in-Terraform is a valid pattern.** The `template_body` heredoc approach wraps a CFN template inside a Terraform resource. Useful for legacy resources.
- 🔍 **`(known after apply)` on a required block means you forgot to set it.** The plan tells you what's missing — read it carefully.
- 🕐 **OpenSearch provisioning is slow (10–15 min).** Patience is part of the task. Ctrl+C leaves broken state.

---

## Day Status

| Area                                     | Status       |
| ---------------------------------------- | ------------ |
| 100 Days DevOps — Docker nginx:alpine    | 🟢 Completed |
| 100 Days Cloud — ALB + Target Group      | 🟢 Completed |
| Personal — CloudFormation stack          | 🟢 Completed |
| Personal — OpenSearch domain             | 🟢 Completed |
| Docker (container run)                   | 🟢 Reinforced |
| AWS (ALB, target groups, SG chaining)    | 🟢 Learned   |
| Terraform (CloudFormation, OpenSearch)   | 🟢 Completed |

**Overall: 🟢 Day 36/100 — Completed**

> **Major realization:** Today's ALB task taught the same lesson as the NAT instance, the VPC peering, and the RDS retry — **the failure is always a missing link, not a wrong command.** The `wait` command hides the reason code. The `describe-target-health` output points directly at the broken link. `Target.NotInUse` was not a registration problem — it was an AZ coverage problem. The fix wasn't to retry, it was to expand the ALB's reach to include the EC2's AZ. Every AWS task this week has followed the same diagnostic pattern: **read the reason code, trace the chain, fix the missing link.** The commands are mechanical. The diagnostic instinct is what compounds.
