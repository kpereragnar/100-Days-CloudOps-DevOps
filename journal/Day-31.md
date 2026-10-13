# CloudOps / DevOps Journal

## Day 31 — 13 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Restore a Specific Git Stash

I was tasked with:

1. In `/usr/src/kodekloudrepos/cluster`, look for stashed changes
2. Restore the stash with identifier `stash@{1}`
3. Commit and push the changes to origin

### What I Did

**Step 1 — SSH'd into the storage server and listed stashes:**

```bash
ssh natasha@ststor01
cd /usr/src/kodekloudrepos/cluster
git stash list
```

Output showed multiple stashes. The second one was `stash@{1}`.

**Step 2 — Inspected the stash before restoring:**

```bash
git stash show -p stash@{1}
```

**Step 3 — Restored the specific stash:**

```bash
git stash apply stash@{1}
```

Used `apply` (not `pop`) because the task said "restore", not "pop". `apply` keeps the stash in the list; `pop` removes it. The task didn't ask for removal.

**Step 4 — Committed and pushed:**

```bash
git add .
git commit -m "Restore stashed changes"
git push origin master
```

**Step 5 — Verified:**

```bash
git log --oneline -3
git stash list
```

### Key Learning

**Stash identifiers matter when there's more than one stash.** The default `git stash pop` or `git stash apply` only touches `stash@{0}` — the most recent. To target a specific one, you must pass the identifier:

```bash
git stash apply stash@{1}
git stash pop stash@{1}
git stash show -p stash@{1}
```

**`apply` vs `pop` — the distinction:**

| Command | Effect |
|---|---|
| `git stash apply stash@{1}` | Restores, keeps in the stash list |
| `git stash pop stash@{1}` | Restores, removes from the stash list |

The task said "restore the stash" — that's `apply`. If it had said "pop" or "remove", it would be `pop`.

**Your sheet had a small gap.** Section 12 covers `git stash apply` and `git stash pop`, but not the `stash@{N}` variant for targeting a specific stash. Worth adding:

```bash
git stash apply stash@{1}     # restore a specific stash (keeps it in the list)
git stash pop stash@{1}       # restore a specific stash (removes it from the list)
git stash show -p stash@{1}   # inspect a specific stash
```

**No issues faced.** Git L1 and L2 covered stash operations thoroughly. This was reinforcement.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Private RDS Instance

I was tasked with:

1. Create a new private RDS instance named `datacenter-rds`
2. Use the Full configuration method with the Free tier template
3. Instance type: `db.t3.micro`
4. Engine: MySQL `8.4.x`
5. Storage: General Purpose SSD (`gp2`) with `20 GiB`
6. Enable Storage autoscaling with a max threshold of `22 GiB`
7. Ensure the instance is in the `available` state

### What I Did

**Step 1 — Created the RDS instance via CLI:**

```bash
aws rds create-db-instance \
  --db-instance-identifier datacenter-rds \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.4 \
  --allocated-storage 20 \
  --storage-type gp2 \
  --max-allocated-storage 22 \
  --no-publicly-accessible \
  --master-username admin \
  --master-user-password 'Adm!n321'
```

**Step 2 — Waited for the instance to become available:**

```bash
aws rds wait db-instance-available --db-instance-identifier datacenter-rds
```

**Step 3 — Verified the configuration matched the task:**

```bash
aws rds describe-db-instances --db-instance-identifier datacenter-rds \
  --query "DBInstances[0].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Engine:Engine,Version:EngineVersion,StorageType:StorageType,Allocated:AllocatedStorage,MaxStorage:MaxAllocatedStorage,Public:PubliclyAccessible,Status:DBInstanceStatus}" \
  --output table
```

All fields matched the task requirements.

### Issues I Faced and How I Fixed Them

**Issue 1 — Two missing flags on the first attempt**

My initial command omitted `--storage-type gp2` and `--no-publicly-accessible`. Without these, AWS defaults to `gp3` storage and a **publicly accessible** instance — both failing the task requirements.

**Fix:** Added both flags to the command.

**Issue 2 — Typo in a follow-up command**

I accidentally ran:

```bash
aws rds start-db-instance --db-instance-identifier datacnter-rds
```

Two problems:
1. Typo — `datacnter` instead of `datacenter`
2. **RDS instances start automatically after creation.** You don't need `start-db-instance` at all.

The command failed with `AccessDenied` — my IAM user doesn't have `rds:StartDBInstance` permission. That's expected and irrelevant, because the instance was already starting on its own.

**Fix:** Just waited. Used `aws rds wait db-instance-available` instead of trying to start it.

### Key Learning

**RDS instances auto-start on creation.** Unlike EC2 (which you might stop/start manually), a new RDS instance goes `creating` → `available` automatically. You don't run `start-db-instance`.

**The `--no-publicly-accessible` flag is what makes an RDS instance private.** Without it, the instance gets a public endpoint — reachable from the internet. That's the opposite of what "private" means in AWS.

**Default storage type is `gp3`, not `gp2`.** The task specifically required `gp2`, so the flag was mandatory. Defaults matter — always check them against the task.

**The flags that map to console wording:**

| Console wording | CLI flag |
|---|---|
| Full configuration | (default — no flag) |
| Free tier template | (no direct equivalent — just means t3.micro + gp2 + single-AZ) |
| Storage type: gp2 | `--storage-type gp2` |
| Storage autoscaling | `--max-allocated-storage 22` |
| Publicly accessible: No | `--no-publicly-accessible` |

**Verify with `describe-db-instances`.** The task lists eight specific requirements. The only way to confirm all eight are met is to query the instance after creation and check each field.

---

## 3. Personal Task — Terraform

### Task: Terraform L1 — Provisioning AWS Resources

Today's work covered the L1 Terraform tasks — creating foundational AWS resources with HCL.

**What was covered:**

| Task | Resources created | Key concepts |
|---|---|---|
| **Elastic IP** | `aws_eip` | `domain = "vpc"`, Name tag |
| **Key pair** | `tls_private_key` + `aws_key_pair` + `local_file` | RSA generation, public key upload, private key to disk with `0400` permissions |
| **EC2 instance** | `aws_instance` | `ami`, `instance_type`, `key_name`, `vpc_security_group_ids`, `data "aws_security_group"` lookup |
| **AMI from instance** | `aws_ami_from_instance` | `source_instance_id` reference, auto-waits for `available` |

### Key Learning

**Terraform resource arguments are case-sensitive and non-intuitive.** Common mistakes that cost time:

| Wrote | Should be |
|---|---|
| `image = "..."` | `ami = "..."` |
| `type = "t2.micro"` | `instance_type = "t2.micro"` |
| `key = "..."` | `key_name = "..."` |
| `name = "devops-eip"` (tag key) | `Name = "devops-eip"` (capital N) |

The AWS CLI uses different names than Terraform for the same concepts. CLI's `--image-id` becomes Terraform's `ami`. CLI's `--instance-type` becomes `instance_type`. CLI's `--key-name` becomes `key_name`. Learning one doesn't mean you know the other.

**Tag keys are case-sensitive.** `Name` (capital N) is the AWS convention. Writing `name` produces a tag called `name` — which the grader won't match. Same with `env` vs `Env` — always match the task's spelling exactly.

**The default security group needs a data source.** To attach the default SG to an instance, you can't just use the string `"default"`. You look it up:

```hcl
data "aws_security_group" "default" {
  name = "default"
}

resource "aws_instance" "ec2" {
  # ...
  vpc_security_group_ids = [data.aws_security_group.default.id]
}
```

**Reference resources instead of hardcoding strings.** For `key_name`, use `aws_key_pair.kp.key_name` rather than `"datacenter-kp"`. This creates an implicit dependency — Terraform's graph knows to create the key pair first.

**`aws_ami_from_instance` waits automatically.** No separate wait step is needed. When `terraform apply` finishes, the AMI is `available`. The `source_instance_id = aws_instance.ec2.id` reference also creates an implicit dependency — the instance is created before the AMI.

**HCL has four value types.** Every `.tf` file is these four, arranged into blocks:

| Type | Example |
|---|---|
| String | `cidr_block = "10.0.0.0/16"` |
| Number | `from_port = 80` |
| List | `cidr_blocks = ["0.0.0.0/0"]` |
| Map | `tags = { Name = "web" }` |

**The four-command workflow is always the same:**

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

### The common failure pattern

**Missing closing quotes produce misleading errors.** When I forgot the closing `"` in a CIDR block, Terraform reported "Invalid multi-line string" at a *different* line — where it gave up parsing, not where the quote was forgotten. The fix is to scan **upwards** from the reported error line for unterminated strings.

**`terraform fmt` after every edit.** Formatting isn't cosmetic — it catches subtle issues like missing spaces before `{`, which can indicate a parsing problem.

**`terraform validate` before `plan`.** It's faster and catches syntax errors without contacting AWS. Always run it before plan.

---

## Key Takeaways

- 🌿 **Target a specific stash with `stash@{N}`.** `git stash apply stash@{1}` restores the second stash without touching the first.
- 🔀 **`apply` keeps the stash, `pop` removes it.** Match the verb to the task's wording.
- ☁️ **RDS instances auto-start after creation.** Don't run `start-db-instance`. Wait for `available` instead.
- 🔒 **`--no-publicly-accessible` makes RDS private.** Without it, the instance gets a public endpoint — the opposite of "private".
- 💾 **Default storage type in RDS is `gp3`, not `gp2`.** If the task specifies `gp2`, you must pass the flag.
- 🧩 **CLI flag names differ from Terraform argument names.** `--image-id` → `ami`, `--instance-type` → `instance_type`, `--key-name` → `key_name`. Learning one doesn't mean you know the other.
- 🏷️ **Tag keys are case-sensitive.** `Name` with a capital N. Match the task exactly.
- 🔗 **Reference resources, don't hardcode.** `aws_key_pair.kp.key_name` creates a dependency. `"datacenter-kp"` doesn't.
- 📖 **Find the exact string in the error, not the line.** Terraform reports errors where parsing fails, not where the mistake was made. Scan upwards.

---

## Day Status

| Area                                | Status       |
| ----------------------------------- | ------------ |
| 100 Days DevOps — Git stash         | 🟢 Completed |
| 100 Days Cloud — Private RDS        | 🟢 Completed |
| Personal — Terraform (L1 tasks)     | 🟢 Completed |
| Git (specific stash targeting)      | 🟢 Reinforced |
| AWS (RDS provisioning)              | 🟢 Completed |
| Terraform (EIP, key pair, EC2, AMI) | 🟢 Completed |

**Overall: 🟢 Day 31/100 — Completed**

> **Major realization:** Both the Git and Terraform tasks came down to the same lesson — **the tools have exact syntax, and being close isn't enough.** `git stash apply` without `stash@{1}` restores the wrong stash. `image = "..."` instead of `ami = "..."` fails at plan time. `name = "devops-eip"` instead of `Name = "devops-eip"` produces a tag the grader never sees. And on the RDS side, the default storage type and public accessibility were silent traps — the instance created successfully but with the wrong values. The pattern is consistent: **read the task literally, check the defaults, verify after creation.** Small mistakes compound into failed tasks — and in production, into broken infrastructure.
