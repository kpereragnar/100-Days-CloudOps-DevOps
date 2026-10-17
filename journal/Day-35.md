# CloudOps / DevOps Journal

## Day 35 — 17 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Install Docker and Docker Compose, Start the Services

I was tasked with installing Docker and Docker Compose on a target host and ensuring both services are running.

### What I Did

**Step 1 — Tried to install docker-compose directly:**

```bash
sudo yum install -y docker-compose
```

Failed:

```
No match for argument: docker-compose
Error: Unable to find a match: docker-compose
```

**Step 2 — Tried to add the Docker repo (wrong syntax):**

```bash
sudo yum-config-manager --add-repo <https://download.docker.com/linux/centos/docker-ce.repo>
```

Failed:

```
-bash: syntax error near unexpected token `newline'
```

**Step 3 — Fixed the syntax and added the repo:**

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

**Step 4 — Installed the correct package:**

```bash
sudo yum install -y docker-compose-plugin
```

**Step 5 — Started Docker:**

```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
```

**Step 6 — Verified:**

```bash
docker compose version
```

### Issues I Faced and How I Fixed Them

**Issue 1 — `docker-compose` not found in default repos**

CentOS's default repositories don't carry Docker Compose. The standalone `docker-compose` Python package has been deprecated and replaced by the `docker-compose-plugin` (a Go binary that installs as a Docker subcommand).

**Fix:** Add Docker's official repo, then install `docker-compose-plugin` (not `docker-compose`).

**Issue 2 — `yum-config-manager --add-repo <URL>` failed with syntax error**

I copy-pasted a command that had angle brackets around the URL:

```bash
sudo yum-config-manager --add-repo <https://download.docker.com/linux/centos/docker-ce.repo>
```

The `<` and `>` are **shell redirection operators**. Bash interpreted `<https://...>` as "read from a file named https://..." — which is nonsense, hence the syntax error.

**Fix:** Remove the angle brackets. URLs are passed as-is:

```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### Key Learning

**`docker-compose` (hyphen) vs `docker compose` (space).**

| Form | What it is | Package |
|---|---|---|
| `docker-compose` | Old standalone Python binary | Deprecated, often not in repos |
| `docker compose` | Modern Docker subcommand | Installed via `docker-compose-plugin` |

The plugin approach is the current standard. Any tutorial mentioning `pip install docker-compose` or a standalone binary is outdated.

**Angle brackets in documentation are placeholders, not syntax.**

When docs write `<URL>` or `<region>` or `<your-name>`, the brackets mean "replace this." They are **not** part of the command. Copy-pasting them into bash triggers redirection errors or literal-text errors.

| Written in docs | What you actually type |
|---|---|
| `<https://example.com>` | `https://example.com` |
| `<region>` | `us-east-1` |
| `<your-instance-id>` | `i-0abc123def456789` |

**Removing brackets is a habit worth building.** It's a mistake that shows up in every DevOps log at least once.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Private RDS Instance + EC2 Connection + PHP Web App

I was tasked with:

1. Create a private RDS instance `datacenter-rds` with MySQL 8.4.5, `db.t3.micro`, gp2 storage 5 GiB, master user `datacenter_admin`, database `datacenter_db`
2. Configure security groups: RDS allows 3306 from EC2, EC2 allows port 80 from the internet
3. SSH into `datacenter-ec2` from aws-client via a key added through the AWS Console
4. Copy `index.php` from aws-client to `/var/www/html/` and configure it for RDS
5. Verify "Connected successfully" in the browser

### What I Did

**Step 1 — Created the RDS security group and inbound rule:**

```bash
RDS_SG=$(aws ec2 create-security-group \
  --group-name datacenter-rds-sg \
  --description "Allow MySQL from datacenter-ec2" \
  --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG" \
  --protocol tcp --port 3306 --source-group "$EC2_SG"
```

**Step 2 — Created the RDS instance:**

```bash
aws rds create-db-instance \
  --db-instance-identifier datacenter-rds \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.4.5 \
  --no-auto-minor-version-upgrade \
  --allocated-storage 5 \
  --storage-type gp2 \
  --master-username datacenter_admin \
  --master-user-password 'DatacenterAdmin123!' \
  --db-name datacenter_db \
  --no-publicly-accessible \
  --vpc-security-group-ids "$RDS_SG"
```

**Step 3 — Opened port 80 on the EC2's security group:**

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$EC2_SG" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

**Step 4 — Generated a key and added it to the EC2 via the AWS Console:**

```bash
# On aws-client
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""
cat /root/.ssh/id_rsa.pub
```

Inside the **EC2 Instance Connect** console session:

```bash
sudo -i
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "ssh-rsa AAAA... root@aws-client" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

**Step 5 — SSH'd in and copied the file:**

```bash
# From aws-client
scp -i /root/.ssh/id_rsa /root/index.php root@$EC2_PUBLIC_IP:/var/www/html/

# Then
ssh -i /root/.ssh/id_rsa root@$EC2_PUBLIC_IP
vi /var/www/html/index.php
# Updated DB host, user, password, and DB name
rm -f /var/www/html/index.html
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Task failed on the first submission: wrong MySQL version**

The grader reported:

```
RDS instance 'datacenter-rds' is not using MySQL version 8.4.5.
```

**Root cause:** My first attempt used `--engine-version 8.4` (without the `.5`). AWS resolves `8.4` to the **latest patch** in the 8.4 family at creation time — likely 8.4.6 or 8.4.7. The grader wanted the exact string `8.4.5`.

Additionally, I did not pass `--no-auto-minor-version-upgrade`. Even if I had created 8.4.5 correctly, AWS could have bumped it to 8.4.6 at the next maintenance window.

**Fix:**

```bash
aws rds modify-db-instance \
  --db-instance-identifier datacenter-rds \
  --engine-version 8.4.5 \
  --no-auto-minor-version-upgrade \
  --apply-immediately

aws rds wait db-instance-available --db-instance-identifier datacenter-rds
```

Then verified:

```bash
aws rds describe-db-instances --db-instance-identifier datacenter-rds \
  --query "DBInstances[0].[EngineVersion,AutoMinorVersionUpgrade]" --output text
# 8.4.5   False
```

**Issue 2 — SSH kept timing out**

I tried:

```bash
ssh -i /root/.ssh/id_rsa root@172.31.95.211
```

Verbose output:

```
debug1: connect to address 172.31.95.211 port 22: Connection timed out
```

**Root cause:** `172.31.95.211` is the **private IP** of `datacenter-ec2`. Private IPs are only reachable from **inside the VPC**. aws-client is outside the VPC — it needs the **public IP**.

**Fix:** Retrieved the public IP:

```bash
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=datacenter-ec2" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

ssh -i /root/.ssh/id_rsa root@$EC2_PUBLIC_IP
```

**Issue 3 — No key pair attached to the EC2 instance**

The instance was launched without a key pair. `ssh -i` alone doesn't work — the key must already be in `authorized_keys` on the instance. Without a way to authenticate, there was no path to bootstrap.

**Root cause:** I assumed `ssh -i` would work because the file existed locally. It doesn't. `-i` provides the key that **offers** authentication, but the instance must **accept** it.

**Fix:** Used **EC2 Instance Connect** in the AWS Console — this works without a key pair because the Instance Connect agent pushes an ephemeral key at connection time. Used that session to permanently add my key to `/root/.ssh/authorized_keys`.

### Key Learning

**RDS engine version pinning — the two-flag rule:**

| Flag | Why |
|---|---|
| `--engine-version 8.4.5` | Full version string. `8.4` resolves to latest patch. |
| `--no-auto-minor-version-upgrade` | Stops AWS from drifting to a newer patch. |

Both are required. Missing either one means the grader (or a future user) sees a version that isn't what you declared.

**Public IP vs private IP:**

| Type | Range | Reachable from |
|---|---|---|
| Private IP | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | Inside the VPC only |
| Public IP | Everything else | Internet (if the SG allows it) |

The EC2 console shows both. When you're SSHing from outside AWS, use the **public** IP.

**`ssh -i` is not a magic key.** It provides the key for authentication — but only works if the instance's `authorized_keys` contains that key's public half. When the instance was launched without a key pair, there's nothing to authenticate against.

**The bootstrap chain:** When there's no key pair:
1. Use EC2 Instance Connect (console or `aws ec2-instance-connect send-ssh-public-key`)
2. Add your key to `authorized_keys`
3. Then `ssh -i` works

You cannot skip step 1 without a pre-existing key pair.

**Security group chaining:** The RDS rule references the EC2's **security group ID**, not its IP:

```bash
--source-group "$EC2_SG"
```

This means "any instance attached to that SG can connect." If the EC2's IP changes, the rule still holds. That's the production-correct pattern.

---

## 3. Personal Tasks — Terraform

Two Terraform tasks today, each small but each teaching a pattern.

### Task 1: SSM Parameter

```hcl
resource "aws_ssm_parameter" "datacenter_ssm" {
  name  = "datacenter-ssm-parameter"
  type  = "String"
  value = "datacenter-value"
}
```

Three arguments. One resource. SSM parameters are among the simplest Terraform tasks.

**Parameter types:**

| Type | Encryption | Use case |
|---|---|---|
| `String` | None | Non-secret config |
| `StringList` | None | Comma-separated values |
| `SecureString` | KMS | Passwords, API keys |

**Verified with:**

```bash
aws ssm get-parameter \
  --name datacenter-ssm-parameter \
  --endpoint-url=http://aws:4566 \
  --region us-east-1
```

### Task 2: CloudWatch Log Group + Log Stream

The first attempt was wrong:

```hcl
resource "aws_cloudwatch_log_group" "nautilus_log" {
    name = "nautilus-log-group"
    stream_name = "nautilus-log-stream"   # ❌ invalid argument
}
```

`stream_name` doesn't exist on `aws_cloudwatch_log_group`. Log groups and log streams are **two separate resources**.

**Corrected:**

```hcl
resource "aws_cloudwatch_log_group" "nautilus_log" {
  name = "nautilus-log-group"
}

resource "aws_cloudwatch_log_stream" "nautilus_stream" {
  name           = "nautilus-log-stream"
  log_group_name = aws_cloudwatch_log_group.nautilus_log.name
}
```

**Verified with:**

```bash
aws logs describe-log-groups --log-group-name-prefix nautilus-log-group \
  --endpoint-url=http://aws:4566 --region us-east-1

aws logs describe-log-streams --log-group-name nautilus-log-group \
  --endpoint-url=http://aws:4566 --region us-east-1
```

### Key Learning

**CloudWatch logs are hierarchical:**

```
Log Group (container)
    └── Log Stream (sequence of events)
```

You cannot create a stream without a group. The stream references the group via `log_group_name`.

**The Terraform sheet had a gap here.** It listed `aws_cloudwatch_log_stream` in the resource lookup table (6.3), but the skeleton (6.4) and the CLI translation (6.7.2) only covered `aws_cloudwatch_log_group`. Today's task exposed that — the sheet was updated with:

- Full skeleton showing both resources together
- CLI table for `aws_cloudwatch_log_stream`:

| AWS CLI | Terraform | Notes |
|---|---|---|
| `--log-group-name` | `log_group_name` | rule |
| `--log-stream-name` | `name` | ⚠️ shortened |

- Exception added to 6.7.3: `--log-stream-name` → `name`

**The pattern:** Whenever a resource has a "child" resource (group → stream, route table → route, cluster → service), the sheet may list the parent but miss the child. Today's gap is now closed.

**SSM parameter types — one argument tells the whole story.** `type` determines everything about how the parameter behaves (encryption, retrieval, access control). Same argument name in Terraform as in the CLI. No exceptions.

---

## Key Takeaways

- 🐳 **`docker-compose` is dead — use `docker-compose-plugin`.** The modern form is `docker compose` (subcommand), installed via Docker's repo.
- 🔤 **Angle brackets in docs are placeholders.** `<URL>`, `<region>`, `<your-name>` — replace them, don't paste them.
- 🗄️ **RDS version pinning requires two flags:** `--engine-version 8.4.5` (exact) + `--no-auto-minor-version-upgrade` (stop drift). Both or the grader fails you.
- 🌐 **`172.31.x.x` is a private IP.** Unreachable from outside the VPC. Use the public IP for SSH.
- 🔑 **`ssh -i` needs `authorized_keys` to exist.** No key pair on the instance means no key-based auth, even if the private key exists locally. Use EC2 Instance Connect to bootstrap.
- 🔗 **Security group chaining** — RDS allows 3306 from EC2's **SG ID**, not its IP. Survives IP changes.
- 📊 **CloudWatch = group + stream.** Two resources. The stream references the group via `log_group_name`.
- 🎯 **Verify before submitting.** Last submission failed because I didn't run `describe-db-instances` after creation to confirm `8.4.5`. A 10-second check would have caught it.
- 📖 **The Terraform sheet has gaps.** CloudWatch log stream was one. Now closed. Every task either reinforces or reveals — today revealed.

---

## Day Status

| Area                                        | Status       |
| ------------------------------------------- | ------------ |
| 100 Days DevOps — Docker + Compose install  | 🟢 Completed |
| 100 Days Cloud — RDS + EC2 + PHP (2nd try)  | 🟢 Completed |
| Personal — SSM parameter                    | 🟢 Completed |
| Personal — CloudWatch log group + stream    | 🟢 Completed |
| Docker / YUM repo handling                  | 🟢 Learned   |
| AWS (RDS version pinning, SG chaining, SSH) | 🟢 Reinforced |
| Terraform (SSM, CloudWatch logs)            | 🟢 Completed |

**Overall: 🟢 Day 35/100 — Completed**

> **Major realization:** The RDS task failed for one reason — I never verified the output of the command I ran. `--engine-version 8.4` created an instance, the command returned successfully, and I assumed success. But success of the API call ≠ correctness of the result. The grader checked the actual version, and it was wrong. The fix was trivial (modify, wait, verify). The lesson isn't trivial: **always read back the state after every creation.** `aws rds describe-db-instances` takes 2 seconds. `terraform state show` takes 2 seconds. `docker compose version` takes 2 seconds. These are cheap. Missing them costs a submission and an hour of re-debugging. Every tool has a "describe" or "show" command for exactly this reason. Use them.
