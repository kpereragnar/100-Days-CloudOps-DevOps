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

**`post-update` is a server-side hook, not a local hook.** It lives in the **bare repo** that receives the push — not in the working repo's `.git/hooks/` directory. This is the trap.

**Server-side hooks receive the updated refs as arguments.** That's why the hook loops over `"$@"` — the list of refs that were pushed. The check `if [ "$ref" = "refs/heads/master" ]` ensures the tag is only created when master was actually updated.

**`git tag -f` is the safe form.** If the hook fires twice on the same day, the tag already exists. Without `-f`, the second push fails. With `-f`, the tag re-points to the newest commit.

**`date +%Y-%m-%d` produces the exact format the task requires.** No underscores, no slashes. `2026-10-16` → `release-2026-10-16`.

**The `remote:` prefix confirms the hook ran on the server side.**

**The hook must be executable.** `chmod +x hooks/post-update` — without it, Git silently skips it.

**The bare repo path matters.** If the origin is a remote URL (GitHub, Gitea), you can't create a hook there. Always check with `git remote -v` first.

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

**Step 3 — Checked the role existed:**

```bash
aws iam get-role --role-name lambda_execution_role
```

Role existed from a previous task — no need to recreate.

**Step 4 — Retrieved the ARN and created the Lambda:**

```bash
ROLE_ARN=$(aws iam get-role --role-name lambda_execution_role \
  --query "Role.Arn" --output text)

aws lambda create-function \
  --function-name datacenter-lambda-cli \
  --runtime python3.12 \
  --role "$ROLE_ARN" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb:///tmp/function.zip
```

**Step 5 — Waited for Active:**

```bash
for i in {1..20}; do
  STATE=$(aws lambda get-function --function-name datacenter-lambda-cli \
    --query "Configuration.State" --output text)
  echo "State: $STATE"
  [ "$STATE" = "Active" ] && break
  sleep 5
done
```

**Step 6 — Invoked:**

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

**Issue 1 — AWS CLI v1 payload limitation**

Knew from Day 33 that `--cli-binary-format` doesn't exist in v1 and `--payload 'e30='` fails on v1. Fixed by omitting `--payload` entirely.

**Issue 2 — Function was Pending after creation**

Invoking a function in `Pending` state fails with `ResourceConflictException`. Fixed by polling until `Active`.

### Key Learning

**Lambda deployment is a three-piece pattern.** Code + zip + role. Miss any one and it fails.

**`fileb://` vs `file://`.** Zip is binary — `fileb://`. Text files use `file://`.

**The handler is `file.function`.** `lambda_function.lambda_handler` = file `lambda_function.py`, function `lambda_handler`.

**The role must exist before the function.** Lambda assumes it at runtime.

**Omit `--payload` on v1 CLI.** Sidesteps the base64 vs raw JSON mess.

**Two status codes mean different things.** Outer `StatusCode: 200` = invocation succeeded. Inner `statusCode: 200` = what the function returned. The task cares about the inner one.

---

## 3. Personal Tasks — Terraform

### Task 1: DynamoDB Table

```hcl
resource "aws_dynamodb_table" "devops_users" {
  name         = "devops-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "devops_id"

  attribute {
    name = "devops_id"
    type = "S"
  }

  tags = {
    Name = "devops-users"
  }
}
```

**Issues:** Started with three wrong argument names:

| Wrote | Correct |
|---|---|
| `key_schema = "devops_id"` | `hash_key = "devops_id"` + `attribute {}` block |
| `mode = "PAY_PER_REQUEST"` | `billing_mode = "PAY_PER_REQUEST"` |
| (missing) | `attribute { name = "devops_id" type = "S" }` |

**Learning:** Terraform uses a **shortcut** for the key schema. The CLI's `--key-schema` flag becomes Terraform's `hash_key`/`range_key` attributes. The `attribute {}` block declares the key's **type** (S=String, N=Number, B=Binary). One block per key. Both are mandatory.

**Why no `--mode`:** The CLI flag `--billing-mode` maps to Terraform's `billing_mode`. There is no `mode` argument on `aws_dynamodb_table`.

---

### Task 2: Kinesis Stream

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

**Learning:** Two required arguments for a basic stream — `name` and `shard_count`. The `stream_mode_details` block sets PROVISIONED vs ON_DEMAND.

| Mode | Shard count | Use case |
|---|---|---|
| `PROVISIONED` | Required | Predictable throughput |
| `ON_DEMAND` | Not allowed | Unpredictable traffic |

**For ON_DEMAND:**

```hcl
resource "aws_kinesis_stream" "stream" {
  name = "nautilus-stream"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}
```

**Verified with:**

```bash
aws kinesis describe-stream-summary \
  --stream-name nautilus-stream \
  --endpoint-url=http://aws:4566 \
  --region us-east-1
```

**Why Kinesis was missing from the sheet:** The sheet's Serverless & Messaging section only had Lambda, SNS, SQS, and EventBridge. Kinesis wasn't in there. Today's task exposed the gap.

---

### Task 3: SNS Topic

```hcl
resource "aws_sns_topic" "datacenter_alerts" {
  name         = "datacenter-alerts"
  display_name = "DataCenter Alerts"

  tags = {
    Name = "datacenter-alerts"
  }
}
```

**Learning:** SNS topics are simple — `name` is the only required argument. Optional ones worth knowing:

| Argument | Purpose |
|---|---|
| `display_name` | Human-readable name shown in SMS/email |
| `policy` | Access policy (JSON) |
| `delivery_policy` | Retry/backoff rules |
| `fifo_topic` | Enables FIFO mode |
| `content_based_deduplication` | Required for FIFO |
| `kms_master_key_id` | Server-side encryption |
| `tags` | Resource tags |

**To subscribe an endpoint (email, SQS, Lambda, etc.):**

```hcl
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.datacenter_alerts.arn
  protocol  = "email"
  endpoint  = "ops@example.com"
}
```

**Verified with:**

```bash
aws sns list-topics \
  --endpoint-url=http://aws:4566 \
  --region us-east-1
```

---

## Key Takeaways

- 🪝 **Server-side hooks live in the bare repo, not the working repo.** `post-update` goes in `/path/to/repo.git/hooks/`.
- 🏷️ **`git tag -f` prevents hook failures on repeated pushes.** Re-points the tag instead of erroring.
- 📅 **Date format is exact.** `date +%Y-%m-%d` → `release-2026-10-16`.
- 🐍 **Lambda deploy is code + zip + role.** Three pieces, always.
- 📦 **`fileb://` for binary, `file://` for text.** Zip is binary.
- ⏳ **Wait for Lambda `Active` before invoking.** Right after create, it's `Pending`.
- 💡 **Omit `--payload` on v1 CLI.** Sidesteps base64 vs raw JSON.
- 🔑 **DynamoDB uses `hash_key`, not `key_schema`.** Plus an `attribute {}` block for the key type.
- 📊 **Kinesis requires `shard_count` when PROVISIONED.** ON_DEMAND omits it.
- 📢 **SNS topics only need `name`.** Everything else is optional.
- 📖 **The reference sheet is a living document.** Today's tasks revealed missing entries for DynamoDB, Kinesis, and SNS — all three now added.

---

## Day Status

| Area                                     | Status       |
| ---------------------------------------- | ------------ |
| 100 Days DevOps — Git post-update hook   | 🟢 Completed |
| 100 Days Cloud — Lambda + IAM role       | 🟢 Completed |
| Personal — DynamoDB table                | 🟢 Completed |
| Personal — Kinesis stream                | 🟢 Completed |
| Personal — SNS topic                     | 🟢 Completed |
| Git (server-side hooks, tagging)         | 🟢 Learned   |
| AWS (Lambda deploy, zip, handler)        | 🟢 Reinforced |
| Terraform (DynamoDB, Kinesis, SNS)       | 🟢 Completed |

**Overall: 🟢 Day 34/100 — Completed**

> **Major realization:** Three Terraform resources, three different shapes. DynamoDB hides complexity behind shortcut arguments (`hash_key` instead of `key_schema`). Kinesis has two modes with different required arguments. SNS is almost minimal — just `name`. The pattern across all three: **the resource name tells you what to build, the CLI translation tells you the argument names, and the registry tells you what's required.** Each task exposed a service missing from the reference sheet. All three are now added — the sheet is a working tool, not a static document.
