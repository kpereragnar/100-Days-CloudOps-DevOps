# CloudOps / DevOps Journal

## Day 34 — 16 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Create a Post-Update Git Hook to Auto-Tag Releases

I was tasked with:

1. Merge the feature branch into master
2. Before pushing, create a `post-update` hook
3. The hook must create a release tag named `release-YYYY-MM-DD` (today's date) whenever master is pushed
4. Test the hook at least once and create today's release tag

### What I Did

**Step 1 — Navigated to the repo and inspected remotes:**

```bash
cd /usr/src/kodekloudrepos/<repo>
git branch -a
git remote -v
```

Confirmed the origin was a local bare repo.

**Step 2 — Merged feature into master:**

```bash
git checkout master
git merge feature
```

**Step 3 — Located the bare repo and created the hook:**

```bash
cd /opt/<repo>.git
cat > hooks/post-update << 'EOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
TAG_NAME="release-$TODAY"

for ref in "$@"; do
  if [ "$ref" = "refs/heads/master" ]; then
    git tag -f "$TAG_NAME" master
    echo "Created tag: $TAG_NAME"
  fi
done
EOF

chmod +x hooks/post-update
```

**Step 4 — Pushed to trigger the hook:**

```bash
cd /usr/src/kodekloudrepos/<repo>
git push origin master
```

Output included:

```
remote: Created tag: release-2026-10-16
```

**Step 5 — Verified the tag existed:**

```bash
cd /opt/<repo>.git
git tag
```

### Key Learning

**`post-update` is a server-side hook, not a local hook.** It lives in the **bare repo** that receives the push, not in your working repo. This is the thing that trips people up — the hook isn't in `.git/hooks/` on the developer's machine, it's in `hooks/` on the server side.

**Server-side hooks receive the updated refs as arguments.** That's why the hook uses:

```bash
for ref in "$@"; do
  if [ "$ref" = "refs/heads/master" ]; then
```

`$@` expands to the full paths of every ref that was pushed in this operation. The loop ensures the tag is only created when **master** was actually updated.

**`git tag -f` is the safe form.** If the hook fires twice on the same day (two pushes), the tag already exists. Without `-f`, the second push fails with "tag already exists" and the hook errors. With `-f`, the tag just re-points to the newest commit.

**`date +%Y-%m-%d` produces the exact format the task requires.** No underscores, no slashes. `2026-10-16`, matching `release-2026-10-16`.

**The `remote:` prefix in the push output confirms the hook ran on the server.** That's the signal the hook fired — not something on the client side.

**The hook must be executable.** `chmod +x hooks/post-update` — without it, Git silently skips it.

**The bare repo path matters.** If the origin is a remote URL (GitHub, Gitea), you can't create a hook there. The task must provide a local bare repo as origin. Always check with `git remote -v` first.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Lambda Function with IAM Role (CLI)

I was tasked with:

1. Create a Python script `lambda_function.py` that returns body `Welcome to KKE AWS Labs!` with status code 200
2. Zip it into `function.zip`
3. Create a Lambda function named `datacenter-lambda-cli` using Python runtime and the zip
4. Use the IAM role `lambda_execution_role`

### What I Did

**Step 1 — Wrote the Python function:**

```bash
cat > /tmp/lambda_function.py << 'EOF'
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Welcome to KKE AWS Labs!'
    }
EOF
```

**Step 2 — Zipped it:**

```bash
cd /tmp
zip function.zip lambda_function.py
```

**Step 3 — Checked the role:**

```bash
aws iam get-role --role-name lambda_execution_role
```

Role existed from a previous task — no need to recreate.

**Step 4 — Retrieved the role ARN:**

```bash
ROLE_ARN=$(aws iam get-role --role-name lambda_execution_role \
  --query "Role.Arn" --output text)
```

**Step 5 — Created the Lambda:**

```bash
aws lambda create-function \
  --function-name datacenter-lambda-cli \
  --runtime python3.12 \
  --role "$ROLE_ARN" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb:///tmp/function.zip
```

**Step 6 — Waited for Active:**

```bash
for i in {1..20}; do
  STATE=$(aws lambda get-function --function-name datacenter-lambda-cli \
    --query "Configuration.State" --output text)
  echo "State: $STATE"
  [ "$STATE" = "Active" ] && break
  sleep 5
done
```

**Step 7 — Invoked:**

```bash
aws lambda invoke \
  --function-name datacenter-lambda-cli \
  /tmp/response.json

cat /tmp/response.json
```

Output:

```json
{"statusCode": 200, "body": "Welcome to KKE AWS Labs!"}
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Working around the AWS CLI v1 payload problem**

I remembered from Day 33 that `--cli-binary-format` doesn't exist in v1 and that `--payload 'e30='` fails on v1. The fix: omit `--payload` entirely. The function ignores `event`, so an empty event works fine.

**Fix:** Just don't pass a payload.

```bash
aws lambda invoke --function-name datacenter-lambda-cli /tmp/response.json
```

**Issue 2 — Waiting for Active state**

Right after `create-function`, the state was `Pending`. Invoking during `Pending` fails with `ResourceConflictException`.

**Fix:** Poll in a loop until the state is `Active` — 5 to 15 seconds typically.

### Key Learning

**Lambda deployment is a three-piece pattern.**

| Piece | Command |
|---|---|
| Code | Write `lambda_function.py` |
| Package | `zip function.zip lambda_function.py` |
| Function | `aws lambda create-function --zip-file fileb://...` |

Miss any one and the deploy fails.

**`fileb://` vs `file://` matters.**

- `file://` — text files (JSON, trust policies)
- `fileb://` — binary files (zip, images)

The Lambda zip is binary. Use `fileb://`. Without it, the CLI tries to read the zip as text and fails.

**The handler must match the file and function names.**

```
handler = "lambda_function.lambda_handler"
           ^^^^^^^^^^^^^^ ^^^^^^^^^^^^^
           file name      function name
```

`lambda_function.py` contains `lambda_handler`. If the file were `app.py` and the function were `main`, the handler would be `app.main`.

**The role must exist before the function.**

Lambda assumes the execution role when running the function. If the role doesn't exist, `create-function` fails with `InvalidParameterValueException`.

**AWS CLI v1 vs v2 — the payload trap I already knew from Day 33.** The trick is: **omit the payload entirely** and both versions handle the invocation correctly.

**Two status codes mean different things.**

| Code | Meaning |
|---|---|
| `StatusCode: 200` (invoke output) | The invocation succeeded |
| `statusCode: 200` (inside response.json) | The function's return value |

The task cares about the **second one** — what the function returns.

---

## 3. Personal Task — Terraform

### Task: Kinesis Stream + Reference Sheet Expansion

Today's personal work covered the Kinesis data stream task and a comprehensive rewrite of the Terraform reference sheet to close gaps.

**Task — Kinesis stream:**

```hcl
resource "aws_kinesis_stream" "nautilus_stream" {
  name        = "nautilus-stream"
  shard_count = 1

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name = "nautilus-stream"
  }
}
```

Verified with:

```bash
aws kinesis describe-stream-summary \
  --stream-name nautilus-stream \
  --endpoint-url=http://aws:4566 \
  --region us-east-1
```

### Key Learning

**Kinesis was missing from the Terraform sheet.** The task exposed a gap — the sheet had no `aws_kinesis_stream` reference, no CLI translation table, and no skeleton. Fixed by adding:

- Kinesis stream to the resource lookup (6.3)
- Full skeleton with both PROVISIONED and ON_DEMAND modes (6.4)
- CLI → Terraform translation table (6.7.2)
- Exceptions: `--stream-name` → `name`, `--retention-period-hours` → `retention_period` (6.7.3)

**The sheet needed a bigger rewrite.** The Kinesis gap revealed a broader issue: the sheet covered maybe 60% of the AWS services in the 100 Days tasks. Added skeletons, tables, and exceptions for:

Kinesis, Kinesis Firehose, KMS (key + alias), Secrets Manager, SSM Parameter, CloudFront, API Gateway (REST + HTTP), EventBridge, Step Functions, EFS, ECS (cluster + task + service), EKS (cluster + node group), CloudTrail, AWS Config, GuardDuty, Security Hub, Glue, Athena, OpenSearch, Backup.

**The sheet also had structural issues.** Fixed:

| Issue | Fix |
|---|---|
| Section 20 duplicated 6.7.1 | Deleted Section 20 |
| Provisioners and Lifecycle were after Modules/Workspaces | Moved them before — they're part of resource config |
| 6.4 showed minimal skeletons | Expanded to include commonly used arguments per resource |
| Data source section was thin | Added `data "aws_instance"`, `data "aws_security_group"`, `data "aws_subnets"`, etc. |
| Troubleshooting table missing CLI/Terraform mismatch errors | Added `Unsupported argument` and `InvalidParameterValue` rows |

**The sheet is now chronological:** Setup → Author (building blocks → organization patterns) → Execute → Manage/Recover → Reference. Section 6.3 tells you the resource name. Section 6.4 gives you the skeleton. Section 6.7 translates the CLI. Section 14 lists the errors you'll hit.

**The workbook now covers the full 100 Days surface area.** Not just the 15 services hit so far — the 60+ services likely to appear in the remaining days. This was the day the sheet became interview-ready.

---

## Key Takeaways

- 🪝 **Server-side hooks live in the bare repo, not the working repo.** `post-update` must be in `/path/to/repo.git/hooks/` — not `.git/hooks/`.
- 🏷️ **`git tag -f` prevents hook failures on repeated pushes.** If the hook fires twice on the same day, `-f` re-points the tag instead of erroring.
- 📅 **Date format is exact.** `date +%Y-%m-%d` produces `release-2026-10-16`. No underscores, no slashes, no dashes missing.
- 🐍 **Lambda deployment is code + zip + role.** Three pieces. Miss any one and the deploy fails.
- 📦 **`fileb://` for binary, `file://` for text.** The Lambda zip is binary.
- 🎯 **The handler is `file.function`.** `lambda_function.lambda_handler` = file `lambda_function.py`, function `lambda_handler`.
- ⏳ **Wait for `Active` before invoking.** Right after `create-function`, the state is `Pending`.
- 💡 **Omit `--payload` on v1 CLI.** Sidesteps the base64 vs raw JSON mess entirely.
- 📊 **Kinesis has two modes:** PROVISIONED (you set shard count) or ON_DEMAND (auto-scaled). Provisioned requires `shard_count`; on-demand doesn't.
- 📖 **The reference sheet is a living document.** Every new task can expose gaps. Today's task closed 40+ gaps in one pass.

---

## Day Status

| Area                                     | Status       |
| ---------------------------------------- | ------------ |
| 100 Days DevOps — Git post-update hook   | 🟢 Completed |
| 100 Days Cloud — Lambda + IAM role       | 🟢 Completed |
| Personal — Terraform Kinesis stream      | 🟢 Completed |
| Personal — Terraform sheet rewrite       | 🟢 Completed |
| Git (server-side hooks, tagging)         | 🟢 Learned   |
| AWS (Lambda deploy, zip, handler)        | 🟢 Reinforced |
| Terraform (Kinesis + 40 service gaps)    | 🟢 Completed |

**Overall: 🟢 Day 34/100 — Completed**

> **Major realization:** Today was about **closing gaps**. The Kinesis task exposed that the Terraform sheet was incomplete. That wasn't a problem — it was data. The sheet now covers the full surface area of the 100 Days challenge, not just the services hit so far. And the Lambda task exposed the same principle in a different form: what you learn on Day 33 (CLI v1 payload limitations) becomes an asset on Day 34. The pattern is consistent — **every task either reinforces what you already know or reveals a gap worth closing.** The sheet is no longer a cheat sheet; it's a working reference that grows with each task. That's what separates a study guide from a tool.
