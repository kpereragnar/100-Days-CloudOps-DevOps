# CloudOps / DevOps Journal

## Day 33 — 15 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Fix the Story Index and Push Changes to the Gitea Repository

I was tasked with:

1. SSH into the storage server as `max`
2. Push changes to the `story-blog` repository
3. Ensure `story-index.txt` has titles for **all 4 stories**
4. Fix the typo — `Mooose` should be `Mouse` in "The Lion and the Mouse"

### What I Did

**Step 1 — SSH'd into the storage server and entered the repo:**

```bash
ssh max@ststor01
# Password: Max_pass123
cd /home/max/story-blog
ls
```

Files present:

```
fox-and-grapes.txt  frogs-and-ox.txt  lion-and-mouse.txt  story-index.txt
```

**Step 2 — Checked the current index and tried to push:**

```bash
cat story-index.txt
git push origin master
```

Push was rejected:

```
! [rejected] master -> master (fetch first)
```

The remote had commits I didn't have locally.

**Step 3 — Pulled with rebase:**

```bash
git pull --rebase origin master
```

Hit a **conflict** in `story-index.txt` — both my version and the remote version had modified it.

**Step 4 — Resolved the conflict by rewriting the file:**

```bash
cat > story-index.txt << 'EOF'
1. The Fox and the Grapes
2. The Lion and the Mouse
3. The Tortoise and the Hare
4. The Wolf in Sheep's Clothing
EOF
```

**Step 5 — Marked as resolved and continued the rebase:**

```bash
git add story-index.txt
git rebase --continue
```

Output:

```
Successfully rebased and updated refs/heads/master.
```

**Step 6 — Pushed:**

```bash
git push origin master
```

Output:

```
67860ca..ddb102c  master -> master
```

Push succeeded.

**Step 7 — Verified on Gitea:**

- Logged in as `sarah` / `Sarah_pass123`
- Confirmed the commit, the corrected index, and the fixed typo

### Issues I Faced and How I Fixed Them

**Issue 1 — Push rejected (non-fast-forward)**

Another developer (likely Sarah) had pushed to the same branch. My local `master` was behind. Git refuses to push because it would overwrite her commits.

**Fix:** `git pull --rebase origin master` — fetched her commits and replayed mine on top.

**Issue 2 — Rebase conflict in `story-index.txt`**

Both branches modified the same file. Git paused the rebase with conflict markers.

**Fix:** Rewrote the file with the correct content — all 4 titles, no `Mooose`. Then `git add` + `git rebase --continue`.

**Issue 3 — No editor available**

Neither `nano` nor `vim` was installed on the server.

**Fix:** Used a heredoc to overwrite the file directly:

```bash
cat > story-index.txt << 'EOF'
...content...
EOF
```

This writes the file without any editor. Same result, faster.

### Key Learning

**Rebase conflict resolution is the skill, not a bug.** The conflict happened because two people touched the same file. Git paused to let a human decide. The fix wasn't to force-push or skip — it was to resolve the content and continue.

**The full rebase-with-conflict workflow:**

```bash
git pull --rebase origin master
# conflict appears → resolve the file
git add <resolved-file>
git rebase --continue
git push origin master
```

That's the pattern for every future conflict. Four commands.

**Heredocs are the fallback when no editor exists.** `cat > file << 'EOF'` writes the entire file in one shot. No `nano`, no `vim`, no `vi`. Just the shell.

**The order matters:**

```
commit → pull --rebase → resolve → continue → push
```

Never `pull` before `commit`. You'd lose staged changes.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Lambda Function with an IAM Role

I was tasked with:

1. Create a Lambda function named `datacenter-lambda`
2. Use Python runtime
3. The function must return `Welcome to KKE AWS Labs!` with status code `200`
4. Create and use an IAM role named `lambda_execution_role`

### What I Did

**Step 1 — Created the trust policy for Lambda:**

```bash
cat > /tmp/trust.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

**Step 2 — Created the IAM role:**

```bash
aws iam create-role \
  --role-name lambda_execution_role \
  --assume-role-policy-document file:///tmp/trust.json
```

**Step 3 — Attached the execution policy:**

```bash
aws iam attach-role-policy \
  --role-name lambda_execution_role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

**Step 4 — Wrote the Python function:**

```bash
cat > /tmp/lambda_function.py << 'EOF'
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Welcome to KKE AWS Labs!'
    }
EOF
```

**Step 5 — Zipped it:**

```bash
cd /tmp
zip lambda.zip lambda_function.py
```

**Step 6 — Created the Lambda function:**

```bash
ROLE_ARN=$(aws iam get-role --role-name lambda_execution_role \
  --query "Role.Arn" --output text)

aws lambda create-function \
  --function-name datacenter-lambda \
  --runtime python3.12 \
  --role "$ROLE_ARN" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb:///tmp/lambda.zip
```

**Step 7 — Waited for the function to become Active:**

```bash
for i in {1..20}; do
  STATE=$(aws lambda get-function --function-name datacenter-lambda \
    --query "Configuration.State" --output text)
  echo "State: $STATE"
  [ "$STATE" = "Active" ] && break
  sleep 5
done
```

**Step 8 — Invoked the function (no payload):**

```bash
aws lambda invoke \
  --function-name datacenter-lambda \
  /tmp/response.json

cat /tmp/response.json
```

Output:

```json
{"statusCode": 200, "body": "Welcome to KKE AWS Labs!"}
```

### Issues I Faced and How I Fixed Them

**Issue 1 — `--cli-binary-format` not recognized**

I tried the AWS CLI v2 syntax:

```bash
aws lambda invoke \
  --function-name datacenter-lambda \
  --cli-binary-format raw-in-base64-out \
  --payload '{}' \
  /tmp/response.json
```

Error:

```
Unknown options: --cli-binary-format
```

**Root cause:** The lab runs **AWS CLI v1**, not v2. `--cli-binary-format` doesn't exist in v1.

**Issue 2 — Base64 payload rejected**

I tried:

```bash
--payload 'e30='
```

`e30=` is base64 for `{}`. But the CLI passed it through as raw JSON instead of decoding it:

```
Could not parse payload into json: Unrecognized token 'e30'
```

**Root cause:** v1 and v2 disagree on what `--payload` means.

| Behavior | v1 | v2 |
|---|---|---|
| `--payload '{}'` | Treated as base64 → fails | Treated as raw JSON → works |
| `--payload 'e30='` | Treated as raw JSON → fails | Treated as base64 → works |

**The fix:** Omit `--payload` entirely. The function ignores `event` anyway:

```bash
aws lambda invoke \
  --function-name datacenter-lambda \
  /tmp/response.json
```

Both CLI versions handle this the same way. Works every time.

**Issue 3 — Function was Pending after creation**

The function came back with:

```json
"State": "Pending",
"StateReasonCode": "Creating"
```

You can't invoke a function in `Pending` state.

**Fix:** Wait for it to become `Active`:

```bash
aws lambda wait function-active --function-name datacenter-lambda
```

Or poll manually if the waiter isn't available.

### Key Learning

**Lambda = code + role + trigger.** Three pieces. The role is what most people forget.

**IAM roles have two halves:**

| Half | What it does | File |
|---|---|---|
| **Trust policy** | WHO can assume the role (Lambda service) | `/tmp/trust.json` |
| **Permissions policy** | WHAT the role can do once assumed (write logs) | `AWSLambdaBasicExecutionRole` |

Both must exist. Without the trust policy, Lambda can't use the role. Without the permissions policy, the function can run but can't write logs.

**The zip-and-upload workflow:**

```
1. Write Python code
2. zip it
3. Upload via --zip-file fileb://
4. Handler = file.function_name (e.g., lambda_function.lambda_handler)
```

Lambda doesn't take source code directly. It takes a zip.

**`file://` vs `fileb://`:**

- `file://` — text files (JSON, trust policy)
- `fileb://` — binary files (zip, image)

Zips are binary. Use `fileb://`.

**The two "200"s in the invoke output:**

| Where | What it means |
|---|---|
| `StatusCode: 200` (outer) | The invocation succeeded |
| `statusCode: 200` (inner) | What your function returned |

The task cares about the **inner** one. It's inside `/tmp/response.json`.

**AWS CLI v1 vs v2 — the payload trap:**

| Payload | v1 | v2 |
|---|---|---|
| Omitted | ✅ | ✅ |
| `--payload '{}'` | ❌ base64 error | ✅ |
| `--payload 'e30='` | ❌ JSON error | ✅ |
| `--cli-binary-format raw-in-base64-out` | ❌ unknown flag | ✅ |

**When in doubt: omit the payload.** The function doesn't need `event` unless it uses it.

---

## 3. Personal Task — Terraform

### Task: IAM Group and IAM Policy

Two small Terraform tasks today, both IAM-related.

**Task 1 — IAM group:**

```hcl
resource "aws_iam_group" "iamgroup_james" {
  name = "iamgroup_james"

  tags = {
    Name = "iamgroup_james"
  }
}
```

**Task 2 — IAM policy:**

```hcl
resource "aws_iam_policy" "iampolicy_yousuf" {
  name        = "iampolicy_yousuf"
  description = "Read-only access to EC2 instances, AMIs, and snapshots"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### Issues I Faced and How I Fixed Them

**Issue — Three syntax errors in the IAM group resource**

I wrote:

```hcl
resource "aws_iam_groups" iamgroup_james" {
    name = "iamgroup_james"
}
```

Three problems:

| What I wrote | What's wrong | Fix |
|---|---|---|
| `aws_iam_groups` | Plural — resource is singular | `aws_iam_group` |
| `iamgroup_james"` | Missing opening quote | `"iamgroup_james"` |
| (nothing) | No `=` after local name | Add `=` |

**Fix:**

```hcl
resource "aws_iam_group" "iamgroup_james" {
  name = "iamgroup_james"
}
```

### Key Learning

**Terraform resource names are singular.** Even when the AWS CLI uses plurals (`list-groups`, `run-instances`), Terraform resources are singular nouns.

| AWS CLI | Terraform resource |
|---|---|
| `create-group` / `list-groups` | `aws_iam_group` |
| `create-user` / `list-users` | `aws_iam_user` |
| `run-instances` | `aws_instance` |
| `create-bucket` | `aws_s3_bucket` |

**The policy document shape — memorize this:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["<service>:<Verb>"],
      "Resource": "*"
    }
  ]
}
```

Every IAM policy follows this shape. Change the `Action` list, keep everything else.

**Read-only EC2 access maps to three actions:**

| Console view | API call |
|---|---|
| Instances page | `ec2:DescribeInstances` |
| AMIs page | `ec2:DescribeImages` |
| Snapshots page | `ec2:DescribeSnapshots` |

The wildcard `ec2:Describe*` covers all three plus more. Either works — the explicit three match the task wording exactly.

**`jsonencode()` is how Terraform converts HCL to JSON.** You write the policy in HCL syntax, Terraform converts it to the JSON string AWS expects.

**Customer-managed vs AWS-managed policies:**

| Type | Created by | ARN pattern |
|---|---|---|
| AWS-managed | AWS | `arn:aws:iam::aws:policy/...` |
| Customer-managed | You | `arn:aws:iam::<account-id>:policy/<name>` |

The task asked you to **create** a policy, so it's customer-managed. Use `aws_iam_policy` (the resource), not `data "aws_iam_policy"` (the lookup).

---

## Key Takeaways

- 🌿 **Rebase conflicts are part of the workflow, not a bug.** Resolve the file, `git add`, `git rebase --continue`. Four commands — same pattern every time.
- 📝 **Heredocs are the fallback when no editor exists.** `cat > file << 'EOF'` writes an entire file in one shot.
- 🔀 **Order matters:** commit → pull --rebase → resolve → continue → push. Never pull before commit.
- 🐍 **Lambda = code + role + trigger.** The role is what most people forget.
- 🔐 **IAM roles have two halves:** trust policy (who can assume) and permissions policy (what they can do). Both required.
- 📦 **Lambda takes a zip, not source code.** `fileb://` for binary, `file://` for text.
- ⏳ **Wait for Lambda to be Active before invoking.** Right after creation, it's Pending.
- 💡 **AWS CLI v1 vs v2 disagree on `--payload`.** v1 wants base64, v2 wants raw. Omit the payload entirely to sidestep the mess.
- 📋 **Terraform resource names are singular.** `aws_iam_group`, not `aws_iam_groups`. Even when AWS CLI uses plurals.
- 🎯 **The IAM policy document shape is always the same:** `Version` → `Statement[]` → `Effect` → `Action` → `Resource`.

---

## Day Status

| Area                                | Status       |
| ----------------------------------- | ------------ |
| 100 Days DevOps — Git rebase conflict | 🟢 Completed |
| 100 Days Cloud — Lambda function    | 🟢 Completed |
| Personal — Terraform (IAM group + policy) | 🟢 Completed |
| Git (rebase conflict resolution)    | 🟢 Reinforced |
| AWS (Lambda, IAM role, invoke)      | 🟢 Completed |
| Terraform (IAM resources)           | 🟢 Completed |

**Overall: 🟢 Day 33/100 — Completed**

> **Major realization:** Two of today's three tasks failed at first — and both failures were about **version mismatches**. Git's rebase conflicted because two developers touched the same file. The Lambda invoke failed because AWS CLI v1 and v2 disagree on what `--payload` means. Neither was a syntax error — both were environment mismatches the docs assume are consistent. The fix in both cases was to stop fighting the environment and use the path that works everywhere: resolve the conflict manually and continue the rebase; omit the payload entirely and let Lambda handle an empty event. **The tool doesn't adapt to you. You adapt to the tool.** Reading the error carefully — "Unrecognized token 'e30'" and "unmerged files" — was what pointed to the real problem in both cases.
