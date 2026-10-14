# CloudOps / DevOps Journal

## Day 32 — 14 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Rebase a Feature Branch onto Master Without a Merge Commit

I was tasked with:

1. A developer's feature branch has in-progress work
2. New changes have been pushed to `master`
3. Rebase the feature branch onto master **without** losing feature branch data
4. Do **not** create a merge commit

### What I Did

```bash
cd /usr/src/kodekloudrepos/<repo>
git checkout feature
git fetch origin
git rebase master
git push --force-with-lease origin feature
```

Verified with:

```bash
git log --oneline --graph --all
git log --merges        # should be empty
git status
```

### Key Learning

**Rebase vs merge — the difference the task was testing.**

| Method | What happens | Task requirement |
|---|---|---|
| `git merge master` | Creates a **merge commit** | ❌ Task explicitly forbids this |
| `git rebase master` | Replays feature commits **on top of** master — linear history | ✅ Correct approach |

**What rebase actually does:**

```
Before:
master:   A → B → C → D
feature:  A → B → E → F

After git rebase master (while on feature):
master:   A → B → C → D
feature:              E' → F'
```

The feature commits (`E`, `F`) are replayed on top of master's tip. New commits `E'` and `F'` have the same changes but new hashes. No data lost — every change from the feature branch is preserved.

**Force push is mandatory after rebase.** Rebasing rewrites commit hashes, so the local branch diverges from the remote. A normal push is rejected:

```
! [rejected] feature -> feature (non-fast-forward)
```

`--force-with-lease` overwrites the remote but fails safely if someone else pushed since your last fetch. It's the correct choice over plain `--force`.

**No data loss.** This is the key reassurance for developers worried about rebase. Every change survives — only the commit hashes change. The feature branch's working content is identical after the rebase.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Snapshot and Restore an RDS Instance

I was tasked with:

1. Take a snapshot of `nautilus-rds` named `nautilus-snapshot`
2. Restore the snapshot to a new RDS instance `nautilus-snapshot-restore`
3. Ensure the new instance is `db.t3.micro`
4. Verify the restored instance reaches the `available` state

### What I Did

**Step 1 — Confirmed the source instance was available:**

```bash
aws rds describe-db-instances
```

`nautilus-rds` was already in `available` state.

**Step 2 — Created the snapshot:**

```bash
aws rds create-db-snapshot \
  --db-instance-identifier nautilus-rds \
  --db-snapshot-identifier nautilus-snapshot
```

**Step 3 — Waited for the snapshot to complete:**

```bash
aws rds wait db-snapshot-completed --db-snapshot-identifier nautilus-snapshot
```

**Step 4 — Restored the snapshot to a new instance:**

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier nautilus-snapshot-restore \
  --db-instance-class db.t3.micro \
  --db-snapshot-identifier nautilus-snapshot
```

**Step 5 — Waited for the new instance:**

```bash
aws rds wait db-instance-available --db-instance-identifier nautilus-snapshot-restore
```

**Step 6 — Verified:**

```bash
aws rds describe-db-instances --db-instance-identifier nautilus-snapshot-restore \
  --query "DBInstances[0].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Status:DBInstanceStatus,Engine:Engine}" \
  --output table
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Wrong flag on the restore command**

I wrote:

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier nautilus-snapshot-restore \
  --db-instance-type db.t3.micro \
  --db-snapshot-identifier nautilus-snapshot
```

Error:

```
Unknown options: --db-instance-type, db.t3.micro
```

**Root cause:** RDS uses `--db-instance-class`, not `--db-instance-type`. `--instance-type` is an **EC2** concept. I mixed the two.

**Fix:**

```bash
--db-instance-class db.t3.micro
```

**Issue 2 — Unrecognized filter name**

I tried to filter by state:

```bash
aws rds describe-db-instances \
  --filters "Name=db-instance-status,Values=available"
```

Error:

```
Unrecognized filter name: db-instance-status
```

RDS doesn't support `db-instance-status` as a filter. The correct approach is either:

- Describe without filters and check `DBInstanceStatus` in the output
- Use `--query` instead:

```bash
aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceStatus=='available']"
```

### Key Learning

**`db-instance-class` vs `db-instance-type` — the distinction:**

| Service | Correct flag |
|---|---|
| RDS (create and restore) | `--db-instance-class` |
| EC2 | `--instance-type` |
| ECS / Fargate | `--task-definition` or `--launch-type` |

Mixing terminology between services is a common mistake. When in doubt, check `aws rds <command> help`.

**RDS snapshot restore is a two-wait operation:**

1. Wait for the **snapshot** to complete (`db-snapshot-completed`)
2. Wait for the **restored instance** to reach available (`db-instance-available`)

Restoring before the snapshot is ready fails. Verifying before the instance is ready fails. Both waits are mandatory for a successful task.

**Restoring a snapshot creates a new instance — it doesn't modify the original.** The source instance `nautilus-rds` remains untouched. The new instance is a point-in-time copy of the data at snapshot time.

**RDS filters are limited.** Not every field is filterable. When `--filters` doesn't work, use `--query` with JMESPath instead:

```bash
--query "DBInstances[?DBInstanceStatus=='available']"
```

This works regardless of what the API supports as a filter.

---

## 3. Personal Task — Terraform L1

### Task: EBS Volume, Snapshot, and CloudWatch Alarm

Today's Terraform work covered three L1 tasks, each of which taught a distinct lesson.

**Task 1 — EBS volume**

```hcl
resource "aws_ebs_volume" "xfusion_volume" {
  type              = "gp3"
  size              = 2
  availability_zone = "us-east-1a"

  tags = {
    Name = "xfusion-volume"
  }
}
```

**Task 2 — EBS snapshot from the volume**

```hcl
resource "aws_ebs_snapshot" "datacenter_vol_ss" {
  volume_id   = aws_ebs_volume.k8s_volume.id
  description = "Datacenter Snapshot"

  tags = {
    Name = "datacenter-vol-ss"
  }
}
```

**Task 3 — CloudWatch alarm**

```hcl
resource "aws_cloudwatch_metric_alarm" "datacenter_alarm" {
  alarm_name          = "datacenter-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }
}
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Missing quotes**

My first EBS volume had no quotes around string values. Terraform errored with "Unknown variable" because it tried to interpret `gp3` as a variable reference instead of a string.

**Fix:** String values need quotes. Numbers don't.

```hcl
type              = "gp3"           # string → quotes
size              = 2               # number → no quotes
availability_zone = "us-east-1a"    # string → quotes
```

**Issue 2 — Snapshot referencing the volume as a string**

I wrote:

```hcl
volume_id = "k8s_volume"
```

This passes the literal string `"k8s_volume"` to AWS. AWS expects a volume ID like `vol-0abc123...`. The snapshot would fail with `InvalidVolume.NotFound`.

**Fix:** Reference the resource attribute:

```hcl
volume_id = aws_ebs_volume.k8s_volume.id
```

**Issue 3 — CloudWatch alarm failed three times with "resources not created using terraform"**

The grader kept reporting that my alarm wasn't created. This was the hardest of the three.

**Root cause:** I had added an `aws_instance` resource to `main.tf` on every attempt — either as a `resource` or a `data` source. Both failed:

- **As a resource:** The hardcoded AMI `ami-0c101f26f147fa7fd` didn't exist in the LocalStack environment. `terraform apply` failed silently → no state → no alarm created.
- **As a data source:** No EC2 instance existed in the environment, so `terraform plan` failed → no state → no alarm created.

**The fix:** Remove the EC2 instance entirely. The task only asked for a **CloudWatch alarm**. I added the instance because I assumed the alarm needed a real instance to monitor. That assumption was wrong.

```hcl
resource "aws_cloudwatch_metric_alarm" "datacenter_alarm" {
  alarm_name          = "datacenter-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }
}
```

The grader checks the alarm's attributes — name, metric, threshold, period, evaluation_periods. The `InstanceId` value is a placeholder. It doesn't need to be a real instance.

### Key Learning

**Read the task literally. Build only what it asks for.**

> **The verb tells you what to create.** "Create a CloudWatch alarm" does not mean "create an EC2 instance and an alarm". Every extra resource is a chance for the apply to fail.

**The `volume_id` reference pattern:**

```
aws_ebs_volume.k8s_volume.id
^^^^^^^^^^^^^^ ^^^^^^^^^^ ^^
resource type  local name attribute
```

Quotes around it (`"k8s_volume"`) pass a literal string. No quotes reference the actual resource. The reference also creates an **implicit dependency** — Terraform knows to create the volume before the snapshot.

**Quote rules in HCL:**

| Value type | Quotes? | Example |
|---|---|---|
| String | Yes | `type = "gp3"` |
| Number | No | `size = 2` |
| Map key | Optional | `Name =` |
| Map value | Yes | `Name = "xfusion-volume"` |
| Resource reference | No | `volume_id = aws_ebs_volume.k8s_volume.id` |

**Diagnostic order when Terraform fails:**

```bash
terraform plan       # Does the plan succeed?
terraform apply      # Does apply complete?
terraform state list # Is the resource in state?
```

If `terraform state list` is empty, nothing was created — the grader will fail you regardless of what your `main.tf` looks like.

**When a data source returns "no matching resource found", the resource doesn't exist.** Two options:

1. Debug why it's missing (wrong name, wrong region, wrong endpoint)
2. Create it yourself in `main.tf`

The `describe-instances` returning empty in my failed attempts was the clue. The environment had no pre-provisioned EC2 — so I should have either created one properly or removed the dependency entirely. I chose neither on the first three attempts, and it cost me.

**CloudWatch alarm `period` is in seconds.** 5 minutes = `300`, not `5`.

**RDS default storage type is `gp3`, not `gp2`.** When a task specifies `gp2`, the flag is mandatory.

---

## Key Takeaways

- 🌿 **Rebase rewrites history — no merge commit.** `git rebase master` on the feature branch replays feature commits on top of master. Force push with `--force-with-lease` afterwards.
- 🔄 **Rebase doesn't lose data.** Every change survives. Only commit hashes change.
- ☁️ **RDS uses `--db-instance-class`, not `--db-instance-type`.** EC2 uses `--instance-type`. Never mix them.
- ⏳ **Snapshot restore is two waits.** Wait for the snapshot, then wait for the restored instance. Both are mandatory.
- 📖 **RDS filters are limited.** When `--filters` doesn't work, use `--query` with JMESPath instead.
- 🎯 **Read the task literally. Build only what it asks for.** "Create an alarm" ≠ "create an EC2 instance and an alarm". Extra resources cause silent failures.
- 🔗 **Reference resources, don't hardcode strings.** `aws_ebs_volume.k8s_volume.id` — not `"k8s_volume"`. The reference also creates a dependency.
- 📝 **Quote rules in HCL:** strings get quotes, numbers don't, references don't.
- 🔍 **Diagnostic order for Terraform failures:** `plan` → `apply` → `state list`. If state is empty, nothing was created.

---

## Day Status

| Area                                    | Status       |
| --------------------------------------- | ------------ |
| 100 Days DevOps — Git rebase            | 🟢 Completed |
| 100 Days Cloud — RDS snapshot + restore | 🟢 Completed |
| Personal — Terraform L1 (3 tasks)       | 🟢 Completed |
| Git (rebase vs merge)                   | 🟢 Reinforced |
| AWS (RDS snapshot, restore, flags)      | 🟢 Completed |
| Terraform (EBS, snapshot, alarm)        | 🟢 Completed |
| Terraform (scope creep debugging)       | 🟢 Learned   |

**Overall: 🟢 Day 32/100 — Completed**

> **Major realization:** Today's hardest lesson wasn't syntax — it was **scope**. The CloudWatch alarm failed three times because I kept adding a resource the task never asked for. Every failure was a side effect of that one extra resource. The alarm itself was always correct. This is the same lesson as the RDS task: the flag was wrong, but the fix was trivial once I read the error message carefully. And in Git, the task explicitly said "no merge commit" — the fix was to pick `rebase` over `merge`, which is a single-word difference with a completely different result. **The tool doesn't care what you meant to build — only what you actually build.** Read the task. Build exactly that. Verify before submitting. Every time.
