# CloudOps / DevOps Journal

## Day 42 — 24 October 2026

**Challenges:** KodeKloud 100 Days of DevOps, 100 Days of Cloud, and Terraform L1

> **Context:** Power outage for most of the day. Only the Terraform tasks were completed. Both 100 Days streaks reset (KodeKloud doesn't allow catch-up on unpaid tracks). 100 Days Day 100 shifts from 21 Dec → 22 Dec. Everything else unaffected.

---

## 1. Personal Task — Terraform

### Task A: Copy `/tmp/xfusion.txt` to S3 Bucket `xfusion-cp-62690530`

I was tasked with:

1. Copy the file `/tmp/xfusion.txt` to S3 bucket `xfusion-cp-62690530`
2. Do this using Terraform (not AWS CLI through Terraform)
3. Update `main.tf` — do not create a separate `.tf` file

### What I Did

**Step 1 — Confirmed what was already in the working directory:**

```bash
cd /home/bob/terraform
cat main.tf
```

The file already had a `provider` block. So I only needed to add the resource.

**Step 2 — Added `aws_s3_object` to `main.tf`:**

```hcl
resource "aws_s3_object" "xfusion" {
  bucket = "xfusion-cp-62690530"
  key    = "xfusion.txt"
  source = "/tmp/xfusion.txt"
  etag   = filemd5("/tmp/xfusion.txt")
}
```

**Step 3 — Applied:**

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Output:

```
aws_s3_object.xfusion: Creating...
aws_s3_object.xfusion: Creation complete after 1s [id=xfusion.txt]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Step 4 — Verified three ways:**

```bash
# Terraform's view
terraform state list
# → aws_s3_object.xfusion

# AWS's view
aws s3 ls s3://xfusion-cp-62690530/
# → 2026-10-24 ...  xfusion.txt

# Content actually matches
aws s3 cp s3://xfusion-cp-62690530/xfusion.txt /tmp/verify.txt
diff /tmp/xfusion.txt /tmp/verify.txt && echo "MATCH"
```

All three passed.

### Issues I Faced and How I Fixed Them

None — the task was straightforward once the shape was correct.

### Key Learning

**The task wording is the discriminator between two very different correct answers.** This task says *"using Terraform."* Day 39 Task 29 said *"use the AWS CLI through Terraform."* Same task family (upload a file to S3 via Terraform configuration), **opposite correct answers**:

| Task wording | Correct tool | Why |
|---|---|---|
| *"using Terraform"* (today) | `aws_s3_object` — native resource | Idempotent, tracked in state, no shell dependency, `destroy` works |
| *"using AWS CLI through Terraform"* (Day 39) | `null_resource` + `local-exec` running `aws s3 cp` | Task explicitly demands CLI; no native resource for "backup then delete" |

**Reading the task precisely is the skill; the code follows.** The phrasing isn't decoration — it names the grader's expected pattern. Same discipline as Day 41's tag-shape question, just applied to wording instead of flags.

**`key` is the destination name, not the source.** The mapping:

```
s3://xfusion-cp-62690530/xfusion.txt
     └──── bucket ──────┘ └── key ──┘

source = "/tmp/xfusion.txt"    ← where the bytes come from
key    = "xfusion.txt"         ← where they land in the bucket
```

`aws s3 cp` infers the key from the source basename when no destination key is given. **Terraform has no such inference** — `key` is required, and you always type it explicitly. To rename on upload, change `key`:

```hcl
source = "/tmp/xfusion.txt"
key    = "uploads/2026-10-24/data.txt"    # lands at that path in the bucket
```

**`etag = filemd5(...)` is correct for the pattern, but not strictly required by the grader.** This distinction matters:

| Scenario | With `etag` | Without `etag` |
|---|---|---|
| First apply | Uploads ✅ | Uploads ✅ |
| Edit `/tmp/xfusion.txt`, apply again | Hash changed → re-uploads ✅ | Path unchanged → **no re-upload** ❌ — S3 keeps stale version |
| `terraform plan` after local edit | `~ update in place` | `No changes` — silent staleness |

Without `etag`, Terraform only diffs the `source` *path* — a string that hasn't changed. It has no way to know the *bytes* changed. The `etag` forces a hash comparison at plan time. **For the lab, "uploads once" is enough. For real use, "stays in sync" is required.** Include it in both, but know which reason applies.

**Three-layer verification, always.** `terraform state list` is Terraform's view. `aws s3 ls` is AWS's view. `diff` on the downloaded content is the *consumer's* view — the same reader the grader will use. **All three must pass; any one alone is assumption dressed as verification.**

---

### Task B: Create VPC with Name Stored in Variable `KKE_vpc`

I was tasked with:

1. Create a VPC named `datacenter-vpc` using Terraform
2. The VPC name should be stored in a variable named `KKE_vpc`
3. CIDR block: `10.0.0.0/16`
4. Configuration values should be in `variables.tf`; `main.tf` references them
5. Working directory: `/home/bob/terraform`

### What I Did

**Step 1 — Wrote `variables.tf`:**

```hcl
variable "KKE_vpc" {
  description = "Name of the VPC"
  type        = string
  default     = "datacenter-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

**Step 2 — Wrote `main.tf`:**

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.KKE_vpc
  }
}
```

**Step 3 — Applied:**

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Plan output confirmed:

```
  # aws_vpc.this will be created
  + resource "aws_vpc" "this" {
      + cidr_block = "10.0.0.0/16"
      + tags       = { + "Name" = "datacenter-vpc" }
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Step 4 — Verified:**

```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=datacenter-vpc" \
  --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
```

One VPC with CIDR `10.0.0.0/16` and Name tag `datacenter-vpc`.

### Issues I Faced and How I Fixed Them

None — the task was clean. But there was one ambiguity worth noting below.

### Key Learning

**"Variable name" vs "variable value" — opposite positions from where you might read them.** The task says:

> *"The VPC name **datacenter-vpc** should be stored in a variable named **KKE_vpc**."*

Read it slowly:

| Concept | Which token |
|---|---|
| Variable **identifier** (what you type in code) | `KKE_vpc` |
| Variable **value** (the actual VPC name) | `datacenter-vpc` |

In HCL:

```hcl
variable "KKE_vpc" {          # ← identifier
  default = "datacenter-vpc"  # ← value
}
```

And the resource references `var.KKE_vpc`, which resolves to the string `"datacenter-vpc"` at apply time.

The mistake to make here would be `variable "datacenter-vpc" {}` — the human-readable name as the identifier, the machine name as the value. **Same shape as Day 41's tag question** (`--tags TagKey=Name,TagValue=foo` — which token is the key, which is the value), same shape as Day 40's `--vpc-id Values=vpc-...` (an ID argument, not a filter). **The tool's vocabulary is the frame; the value fills the frame. Confusing the two produces silent misconfigurations the tool can't catch for you** — `variable "datacenter-vpc"` would declare fine, apply fine, and create a VPC with no Name tag if you referenced it wrong.

**`KKE_vpc` is case-sensitive.** `var.KKE_vpc` ≠ `var.kke_vpc` ≠ `var.KKE_VPC`. Terraform won't warn — it will say `Reference to undeclared input variable` when you try to reference a name that doesn't exist, which is a decent error but only if you read it. **Match the identifier exactly.**

**No `import` statement exists for `.tf` files.** Terraform merges every `.tf` file in the working directory into a single configuration at plan time. So:

- `variables.tf` declares `variable "KKE_vpc"`
- `main.tf` references `var.KKE_vpc`
- Terraform wires them together **because they're in the same directory**

The task's phrase *"main.tf referencing variables.tf"* means *"the variable used in `main.tf` must be declared in `variables.tf`"* — not that any special syntax connects them. **The file split is for readability, not functionality.** Team convention. Terraform would work identically if both blocks were in one `main.tf`.

**`default` on both variables is what makes apply non-interactive.** Without `default`, `terraform apply` prompts:

```
var.KKE_vpc
  Enter a value: _
```

Interactive prompts break automation. The `default` makes the plan non-interactive. The task said "the value should be stored in `variables.tf`" — storing means it's already set, not provided at apply time. A grader wanting to override without editing the file would use `-var 'KKE_vpc=something-else'`; the default is the fallback, not the only path.

**CIDR: variable vs hardcode — I chose variable.** The task only explicitly says the **name** goes in a variable (`KKE_vpc`). The CIDR is stated separately as a requirement. Strictly, `cidr_block = "10.0.0.0/16"` in `main.tf` would work. But the task says *"the configuration values should be stored in a variables.tf file"* — **plural "values."** Putting both in `variables.tf` is the safer reading and matches the Terraform idiom: everything configurable is a variable. Both solutions probably pass the grader; the two-variable version is the more defensible reading of the wording.

---

## Timeline Impact

Power outage cost one day of 100 Days progress on both tracks. KodeKloud doesn't allow catch-up on unpaid tracks, so the streaks reset rather than being recoverable.

| Track | Before | After |
|---|---|---|
| 100 Days Cloud Day 100 | 21 Dec | **22 Dec** |
| 100 Days DevOps Day 100 | 21 Dec | **22 Dec** |
| 100 Days Day 67 (K8 block) | 18 Nov | **19 Nov** |
| Terraform L1 finish | 27 Oct | **27 Oct** (unchanged) |
| Terraform L2 start | 28 Oct | **28 Oct** (unchanged) |
| K8 L1 + L2 window | 7–18 Nov | **7–18 Nov** (unchanged) |
| K8 L2 finish | 18 Nov | **18 Nov** (unchanged) |
| Project start | 22 Nov | **22 Nov** (unchanged) |
| Project window | 30 days | **31 days** (grew by 1) |

Terraform, K8, and the project plan all land on the same dates because they don't depend on 100 Days streak progress — the coins-based tracks are independent of the daily-counter tracks. **Only the 100 Days finish line moved by one day, and the project window absorbed it as extra time rather than lost time.**

---

## Key Takeaways

- 🔧 **Task wording is the discriminator between two correct answers.** *"Using Terraform"* → `aws_s3_object`. *"Using AWS CLI through Terraform"* → `local-exec`. Same task family, opposite expected pattern. Read the phrasing, not just the intent.
- 🔧 **`key` is the destination name, not the source.** `source` is where bytes come from; `key` is where they land in the bucket. `aws s3 cp` infers the key from the source basename; Terraform requires it explicitly.
- 🔧 **`etag = filemd5(...)` is correct for the pattern, not required by the grader.** First upload works without it. Re-upload after local edit *doesn't* work without it. Two different questions; both matter.
- 🔧 **Verify with the consumer's reader.** `state list` (Terraform's view), `aws s3 ls` (AWS's view), and `diff` on the downloaded content (the grader's view) — all three, or none is proof.
- 🔧 **"Variable name" vs "variable value" are opposite positions.** `variable "KKE_vpc" { default = "datacenter-vpc" }` — identifier first, value second. Reversing them produces a config that declares fine and applies silently wrong.
- 🔧 **No `import` for `.tf` files.** Terraform merges the whole directory. "Main references variables" means "the variable is declared in `variables.tf` and used in `main.tf`" — no syntax connects them.
- 🔧 **`default` in a variable makes apply non-interactive.** Without it, `terraform apply` prompts. Prompts break automation and graders.
- 🔄 **A power outage is not a discipline failure.** 41 of 42 days completed. The streak counter is a UI element measuring consecutive days; the journal is the record of total work. The counter served its purpose — it built the habit — and the habit is what carries forward. **One day lost. Zero dependencies broken.**

---

## Day Status

| Area                                   | Status                     |
| -------------------------------------- | -------------------------- |
| 100 Days DevOps                        | ⏸️ Power outage — not done  |
| 100 Days Cloud                         | ⏸️ Power outage — not done  |
| Personal — Terraform (S3 upload)       | 🟢 Completed               |
| Personal — Terraform (VPC + variables) | 🟢 Completed               |

**Overall: 🟡 Day 42 — Partial (Terraform only)**

> **Realization:** The two tasks today look different — one is S3, one is VPC; one is a resource, one is a variable. But they're the same lesson in different clothing: **a value and the name it goes by are opposite things, and the tool cares which is which.** In `aws_s3_object`, `key` is the *name* and `source` is the *value*. In the VPC variable, `KKE_vpc` is the *name* and `datacenter-vpc` is the *value*. Every mistake in this family — `--tags-specifications` vs `--tags` on Day 41, `Values=vpc-...` on Day 40, `aws_instance_delete` on Day 40 — was the same confusion at a different layer: **mistaking the label for the thing, or the thing for the label.** The tool refuses to interpret intent; it only knows shape. That's why the error messages are so specific and the silent failures so dangerous — the tool can tell you the shape is wrong, but not that you've swapped the two.
>
> And then the power outage closes the day on a different note. **A resilient plan absorbs a power grid failure without cascading.** Terraform L1 still finishes on the 27th. K8 L2 still lands on the 18th. Projects still start on the 22nd. One day moved at the tail end, and the project window grew by a day to absorb it — the plan didn't lose time, it *redistributed* it. That's the difference between a plan built on dependencies (which can fail cascading) and a plan built on buffers (which can fail gracefully). **The streak counter reset. The plan didn't.** Those are not the same thing, and knowing the difference is worth more than the badge the counter awards.
