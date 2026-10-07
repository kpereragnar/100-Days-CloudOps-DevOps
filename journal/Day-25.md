```markdown
# CloudOps / DevOps Journal

## Day 25 — 7 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Create Branch, Commit, Merge, and Push Both Branches

I was tasked with:

1. Create a new branch from `master`
2. Copy an `index.html` file into the repo
3. Add and commit the file
4. Merge the new branch back into `master`
5. Push both branches to `origin`

### What I Did

**Step 1 — Created the new branch from master:**

```bash
git checkout master
git checkout -b xfusion
```

**Step 2 — Copied the file:**

```bash
cp /tmp/index.html .
```

**Step 3 — Added and committed:**

```bash
git add index.html
git commit -m "Add index.html"
```

**Step 4 — Merged back into master:**

```bash
git checkout master
git merge xfusion
```

**Step 5 — Pushed both branches to origin:**

```bash
git push -u origin xfusion
git push origin master
```

### Issues I Faced and How I Fixed Them

**Issue — Assumed `git push -u origin` would push both branches**

On my first attempt, after the merge I ran:

```bash
git push -u origin
```

I **assumed** this would push both `master` and `xfusion` to the origin. It didn't. It only pushed the current branch.

When I checked the remote with:

```bash
git branch -a
```

Only `origin/master` existed on the remote — **there was no `origin/xfusion`**.

**Root cause:** `git push -u origin` without a branch name only pushes the branch you're currently on. It does **not** push every local branch.

**The fix:** Explicitly push each branch:

```bash
git push origin xfusion
git push origin master
```

That created `origin/xfusion` and pushed the commits to both remote branches.

### Key Learning

> **`git push` is branch-specific — it does not push "everything".**

The syntax matters:

| Command | What it pushes |
|---|---|
| `git push` | Current branch → its upstream |
| `git push -u origin <branch>` | `<branch>` → origin, sets upstream |
| `git push origin <branch>` | `<branch>` → origin |
| `git push --all origin` | **All** local branches → origin |
| `git push origin master xfusion` | Both named branches in one command |

If a task says "push both branches," I now know to either:

1. Push them individually (`git push origin <branch>` for each), or
2. Use `git push --all origin` to send everything at once, or
3. Name them explicitly (`git push origin master xfusion`)

**The assumption was the failure.** I didn't verify what actually landed on the remote before submitting. If I'd run `git branch -a` or `git ls-remote origin` after the first push, I would have seen that `xfusion` was missing and fixed it in the same attempt.

**Lesson: verify, don't assume** — this is the same lesson from Day 4 (chmod permissions). Confidence without verification is the same mistake every time, just in a different domain.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Launch EC2 Instance and Create CloudWatch Alarm

I was tasked with:

1. Launch an EC2 instance named `xfusion-ec2` using any Ubuntu AMI
2. Create a CloudWatch alarm named `xfusion-alarm` with:
   - Statistic: Average
   - Metric: CPU Utilization
   - Threshold: >= 90% for 1 consecutive 5-minute period
   - Alarm action: Send a notification to `xfusion-sns-topic`

### What I Did

**Step 1 — Confirmed the SNS topic exists:**

```bash
aws sns list-topics
```

Got the ARN for `xfusion-sns-topic`.

**Step 2 — Found the latest Ubuntu AMI:**

```bash
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)
```

**Step 3 — Launched the instance:**

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=xfusion-ec2}]' \
  --query "Instances[0].InstanceId" --output text)
```

**Step 4 — Waited for the instance to be ready:**

```bash
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
```

**Step 5 — Created the CloudWatch alarm:**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name xfusion-alarm \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 90 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --datapoints-to-alarm 1 \
  --treat-missing-data notBreaching \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_ARN"
```

### Key Learning

**`>=` uses `GreaterThanOrEqualToThreshold`, not `GreaterThanThreshold`.**

This is where people usually get it wrong. The task said ">= 90%" — that's the `>=` operator, which maps to `GreaterThanOrEqualToThreshold`. `GreaterThanThreshold` is strictly `>`.

**The alarm configuration breakdown:**

| Flag | Value | Why |
|---|---|---|
| `--metric-name` | `CPUUtilization` | Standard EC2 metric |
| `--namespace` | `AWS/EC2` | Where the metric lives |
| `--statistic` | `Average` | Task specified |
| `--period` | `300` | 5-minute window = 300 seconds |
| `--threshold` | `90` | 90% |
| `--comparison-operator` | `GreaterThanOrEqualToThreshold` | `>=` |
| `--evaluation-periods` | `1` | 1 consecutive period |
| `--datapoints-to-alarm` | `1` | 1 breach triggers |
| `--alarm-actions` | SNS ARN | Where to notify |

**Evaluation periods vs datapoints to alarm:**

- `--evaluation-periods` — how many periods to look at (rolling window)
- `--datapoints-to-alarm` — how many of those periods must breach

For "1 consecutive period," both are `1`. For stricter alarms (e.g., "3 of 5"), you'd set `--evaluation-periods 5 --datapoints-to-alarm 3`.

**Also learned the ID-lookup pattern for SNS ARNs:**

```bash
aws sns list-topics \
  --query "Topics[?ends_with(TopicArn,':xfusion-sns-topic')].TopicArn" \
  --output text
```

SNS doesn't have a `describe-topic --name` command. You list all topics and filter by matching the topic name inside the ARN. The ARN always ends with `:<topic-name>`, so `ends_with` is the precise filter.

---

## 3. Personal Task

No personal task today — took the day to consolidate notes and review the week's Ansible learnings.

---

## Key Takeaways

- 🌿 **`git push` is not "push everything."** It pushes one branch at a time. Verify with `git branch -a` or `git ls-remote origin` after pushing.
- ✅ **Verify, don't assume.** Same lesson as Day 4. If I'd checked the remote branches before submitting, I'd have caught the missing `xfusion` branch in the first attempt.
- 🧠 **`git push --all origin`** pushes every branch in one command when you need that.
- 📊 **Alarm operators matter.** `>=` → `GreaterThanOrEqualToThreshold`, `>` → `GreaterThanThreshold`. Read the task carefully.
- ⏱️ **`--period` is in seconds.** 5 minutes = 300, not 5.
- 🔔 **`--evaluation-periods` + `--datapoints-to-alarm`** control strictness. Both set to 1 for "1 consecutive period."
- 🔎 **SNS ARN lookup** uses `list-topics` + `--query` with `ends_with` — same ID-lookup pattern as every other AWS resource.
- 📖 **`describe-*` doesn't exist for every service.** SNS, SQS, and some others only have `list-*`, and you filter the output.

---

## Day Status

| Area                       | Status       |
| -------------------------- | ------------ |
| 100 Days DevOps            | 🟢 Completed |
| 100 Days Cloud — AWS       | 🟢 Completed |
| Personal Task              | ⚪ Skipped   |
| Git (branching + push)     | 🟢 Reinforced |
| AWS (CloudWatch + SNS)     | 🟢 Completed |

**Overall: 🟢 Day 25/100 — Completed**

> **Major realization:** Twice this week I failed a task because of an assumption — the ALB routing (missing listener), and the Git push (missing branch). Both times the fix was the same: **stop guessing, run a command that tells you the truth.** `git branch -a` shows what's actually on the remote. `aws elbv2 describe-listeners` shows whether the ALB has a listener. The commands exist. The habit is what I'm building — **verify before submitting, not after.**
```
