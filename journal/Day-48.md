# CloudOps / DevOps Journal

## Day 48 — 30 October 2026

**Challenges:** Terraform L2 — 3 tasks to recover yesterday's missed day

> **Context:** Made up for Day 47's missed Terraform with a 3-task sprint. Plan is back on track.

---

## 1. Terraform L2 — `-replace` Force Recreate of `devops-ec2`

**Task:** Use `terraform apply -replace` to destroy and recreate `devops-ec2` without changing config. New ID must differ. Final `terraform plan` must show "No changes."

**Commands:**

```bash
cd /home/bob/terraform
terraform state list                    # found: aws_instance.ec2
terraform plan                          # → No changes (baseline)

# Capture old ID
terraform state show aws_instance.ec2 | grep " id "

# Force recreate
terraform apply -replace=aws_instance.ec2 -auto-approve
# Plan shows: -/+ aws_instance.ec2 will be replaced
# Apply: 1 added, 0 changed, 1 destroyed

# Verify new ID differs
terraform state show aws_instance.ec2 | grep " id "

# Confirm old terminated, new running
aws ec2 describe-instances --instance-ids <OLD_ID> \
  --query "Reservations[0].Instances[0].State.Name" --output text
aws ec2 describe-instances --instance-ids <NEW_ID> \
  --query "Reservations[0].Instances[0].State.Name" --output text

# Final check
terraform plan                          # → No changes
```

### Key Learning

**`-replace` is the modern replacement for `terraform taint`** — one command instead of two, atomic (taint + apply), and scoped to the apply (doesn't persist in state). Deprecated in Terraform 0.15.2 but still works.

**The `-/+` plan symbol is the diagnostic** — destroy-then-create. Same symbol as when you change an immutable attribute (like `ami` on an instance). **`-replace` forces the `-/+` behavior even when nothing in the config changed.**

**`-target` and `-replace` are siblings** — both take full resource addresses (`aws_instance.ec2`, not `ec2`). `-target` destroys; `-replace` destroys and recreates.

---

## 2. Terraform L2 — 3 EC2 Instances with `count`

**Task:** 3 EC2s (`nautilus-instance-1`, `-2`, `-3`), `t2.micro`, key `nautilus-key`. Use `count`, `locals` for latest AMI via data source, `terraform.tfvars` for values, `outputs.tf` for names.

**Six issues in my first attempt:**

| # | Issue | Fix |
|---|---|---|
| 1 | `KKE_INSTANCE_COUNT` typed as `string` | `type = number` — `count` requires a number |
| 2 | `KKE_INSTANCE_PREFIX = "nautilus-instance[1-3]"` | `"nautilus-instance"` — the `[1-3]` is invalid; numbering comes from `count.index + 1` |
| 3 | `outputs.tf` value empty | `value = aws_instance.this[*].tags["Name"]` — splat collects from all instances |
| 4 | No `main.tf` / `locals.tf` | Both required |
| 5 | No data source for AMI | `data "aws_ami"` in `locals.tf`, referenced by `locals { AMI_ID = ... }` |
| 6 | Key `nautilus-key` might not exist | Check with `describe-key-pairs` before apply |

**Final files:**

```hcl
# variables.tf — KKE_INSTANCE_COUNT as number, others as string
# terraform.tfvars — prefix "nautilus-instance", count 3
# locals.tf
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
locals {
  AMI_ID = data.aws_ami.amazon_linux_2.id
}

# main.tf
resource "aws_instance" "this" {
  count         = var.KKE_INSTANCE_COUNT
  ami           = local.AMI_ID
  instance_type = var.KKE_INSTANCE_TYPE
  key_name      = var.KKE_KEY_NAME
  tags = {
    Name = "${var.KKE_INSTANCE_PREFIX}-${count.index + 1}"
  }
}

# outputs.tf
output "kke_instance_names" {
  value = aws_instance.this[*].tags["Name"]
}
```

**Verify:**

```bash
terraform apply -auto-approve
terraform output kke_instance_names
# → ["nautilus-instance-1", "nautilus-instance-2", "nautilus-instance-3"]

aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nautilus-instance-*" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key=='Name']|[0].Value,Type:InstanceType}" \
  --output table
```

### Key Learning

**`count` requires a number, not a string.** `type = string` with a numeric default looks fine in the variable block, but `count = var.X` fails at plan time with `Invalid count argument`. **Same class as Day 44's `"Sts:AssumeRole"` — valid syntax, wrong type.** The plan catches it — can't accidentally apply.

**The prefix/suffix split.** The prefix variable is the **stable part** (`nautilus-instance`); `count.index + 1` is the **variable part** (`-1`, `-2`, `-3`). Trying to encode `[1-3]` in the variable is trying to specify data the user doesn't actually choose — Terraform computes it. **Variables for user choices, `count.index` for Terraform computations.**

**`[*]` splat is the count-aware output.** `aws_instance.this[*].tags["Name"]` collects from every instance. Without `[*]`, `aws_instance.this.tags["Name"]` fails — the resource is a list when count > 1. **Same shape as `Reservations[].Instances[].InstanceId` in AWS CLI — the `[]` iterates.**

---

## 3. Terraform L2 — EC2 with Elastic IP

**Task:** `datacenter-ec2` (t2.micro, Linux AMI), associated `datacenter-eip`. Output instance name via `KKE_instance_name`, EIP via `KKE_eip`.

**Commands:**

```hcl
# main.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "datacenter" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags          = { Name = "datacenter-ec2" }
}

resource "aws_eip" "datacenter" {
  domain   = "vpc"
  instance = aws_instance.datacenter.id
  tags     = { Name = "datacenter-eip" }
}

# outputs.tf
output "KKE_instance_name" {
  value = aws_instance.datacenter.tags["Name"]
}
output "KKE_eip" {
  value = aws_eip.datacenter.public_ip
}
```

**Verify:**

```bash
terraform apply -auto-approve
terraform output
# → KKE_instance_name = "datacenter-ec2"
# → KKE_eip           = "54.xx.xx.xx"

aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=datacenter-eip" \
  --query "Addresses[0].{PublicIP:PublicIp,AssociatedInstance:InstanceId,Domain:Domain}" \
  --output table
# → AssociatedInstance matches datacenter-ec2's ID

terraform plan    # → No changes
```

### Key Learning

**`domain = "vpc"` is required in provider v4+** — the deprecated `vpc = true` from old tutorials fails with `Unsupported argument`. Same class as Day 44's `"Sts:AssumeRole"` and Day 46's `assign_ipv4_address_on_creation` — **the tutorial's syntax is often the tool's past.**

**The `instance = aws_instance.datacenter.id` line IS the association.** Two valid patterns:

| Pattern | When |
|---|---|
| `aws_eip` with `instance = ...` | Same config manages both — this task |
| `aws_eip` + separate `aws_eip_association` | EIP/instance managed separately, or disassociate first |

**The `KKE_eip` output uses `.public_ip`, not `.id` or `.allocation_id`.** Three valid attributes, three different meanings:

| Attribute | Returns |
|---|---|
| `public_ip` | `"54.xx.xx.xx"` — the stable access point |
| `allocation_id` | `"eipalloc-..."` — AWS internal ID |
| `id` | Same as allocation_id |

**The task says "output the Elastic IP"** — in context, the IP address. `public_ip` is what a user pastes into a browser.

---

## Timeline Update — Terraform L2 Recovered

| Day | Tasks completed | Cumulative |
|---|---|---|
| Day 46 | 2 | 2/20 |
| Day 47 | 0 (AFIT) | 2/20 |
| **Day 48** | **3** | **5/20** |

**Remaining:** 15 tasks over 13 days (Oct 31 – Nov 12).

**Recovery plan:**
- **2/day Oct 31 – Nov 1** (2 days × 2 = 4 tasks, 800 coins)
- **1/day Nov 2 – Nov 12** (11 days × 1 = 11 tasks, 0 coins)
- **Total: 15 tasks · finish Nov 12 · total coins for L2 = 1,600**

**Today's 3-task sprint exactly recovered the missed day.** Same finish date. Same coin budget. The plan absorbed the AFIT day without moving a single downstream milestone.

**Downstream unaffected:**
- K8 L1 starts Nov 13 → Nov 19
- Projects start Nov 22
- 100 Days Day 100 → Dec 22

---

## Key Takeaways

- 🔧 **`-replace` is the modern `terraform taint`.** One command. Atomic. Scoped to apply. `-/+` symbol confirms replace.
- 🔧 **`count` requires a number, not a string.** Type mismatch caught at plan time — the write command fails before AWS is touched.
- 🔧 **Prefix is variable, suffix is `count.index + 1`.** Variables for user choices; index for Terraform computations.
- 🔧 **`[*]` splat is the count-aware output pattern.** `aws_instance.this[*].tags["Name"]` collects from every instance.
- 🔧 **`domain = "vpc"` not `vpc = true`.** Deprecated syntax from old tutorials fails on provider v4.
- 🔧 **`instance = aws_instance.X.id` on the EIP IS the association.** No separate `aws_eip_association` needed when both are in the same config.
- 🔧 **`public_ip` vs `allocation_id` vs `id` — three attributes, three meanings.** Task wording ("Elastic IP") points at the address, not the internal ID.
- 💰 **3-task sprint exactly recovered the missed day.** Same finish date (Nov 12), same coin budget (1,600). Downstream milestones (K8, projects, Day 100) untouched.

---

## Day Status

| Area | Status |
|---|---|
| Terraform L2 — `-replace` on devops-ec2 | 🟢 Completed |
| Terraform L2 — 3 EC2 with `count` | 🟢 Completed (after 6 fixes) |
| Terraform L2 — EC2 + Elastic IP | 🟢 Completed |

**Overall: 🟢 Day 48/100 — Completed · Terraform L2 5/20**

> **Realization:** Three tasks today, three different shape lessons, one shared pattern: **the tool's vocabulary is narrower than the assumption of it.** `count = "3"` looks right but needs a number. `domain = "vpc"` looks like `vpc = true` but the syntax changed. `aws_instance.this[*]` looks optional but fails without it. `-replace` looks like `taint` but takes a full address, not a name. **Same class as the whole week — the error names the exact gap, and the fix is one character or one word away.**
>
> The other thing: **the 3-task sprint was the right response to a missed day.** Not "I'll do 4 tomorrow" — but **"today absorbs yesterday, and nothing downstream moves."** Terraform L2 finishes Nov 12 as planned. K8 starts Nov 13. Projects start Nov 22. **The plan absorbed the AFIT day as designed** — that's what the 2/day acceleration window was for. Day 47's journal said "the plan absorbs a real-world constraint." Day 48 proves it. **The recovery is not heroic — it's the plan working.**
