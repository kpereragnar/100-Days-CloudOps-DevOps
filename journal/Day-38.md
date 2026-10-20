# CloudOps / DevOps Journal

## Day 38 — 20 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Pull `busybox:musl` and Re-Tag as `busybox:blog` on App Server 3

I was tasked with:

1. SSH into App Server 3
2. Pull the `busybox:musl` image from Docker Hub
3. Re-tag it as `busybox:blog`

### What I Did

**Step 1 — SSH into App Server 3:**

```bash
ssh banner@stapp03
sudo su -
```

**Step 2 — Pulled the image:**

```bash
docker pull busybox:musl
```

**Step 3 — Re-tagged it:**

```bash
docker tag busybox:musl busybox:blog
```

**Step 4 — Verified:**

```bash
docker images
```

Output showed both tags pointing at the same image ID:

```
REPOSITORY   TAG     IMAGE ID       CREATED       SIZE
busybox      blog    32006d2bebf5   6 weeks ago   1.4MB
busybox      musl    32006d2bebf5   6 weeks ago   1.4MB
```

### Key Learning

**`docker tag` doesn't copy the image — it creates a second name pointing at the same bytes.** The image ID is identical. No additional disk space is used. This is why re-tagging takes under a second even for large images.

**The syntax reads backwards from intuition.** `docker tag <source> <target>` — the source is the existing image, the target is the new name. People sometimes reverse it because "tag" sounds like it applies to the source.

**Why you'd re-tag:** preparing an image for a private registry, marking it for a specific environment (`blog` vs `production`), or keeping a "known good" alias alongside a moving tag.

**This was the easiest task of the week** — Docker L1, L2, and L3 had already covered every part of it. The commands were muscle memory. The learning was just recognizing how much had become automatic.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Full ECS Deployment — ECR → Cluster → Task Definition → Service

I was tasked with:

1. Create a private ECR repository `datacenter-ecr`
2. Build a Docker image from `/root/pyapp` and push it to ECR with the `latest` tag
3. Create an ECS cluster `datacenter-cluster` with Fargate launch type
4. Create a task definition `datacenter-taskdefinition` referencing the ECR image
5. Deploy a service `datacenter-service` running at least one task

### What I Did

**Step 1 — Created the ECR repository:**

```bash
aws ecr create-repository \
  --repository-name datacenter-ecr \
  --image-scanning-configuration scanOnPush=true
```

**Step 2 — Built the Docker image:**

```bash
cd /root/pyapp
docker build -t datacenter-ecr:latest .
```

**Step 3 — Tagged for ECR:**

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag datacenter-ecr:latest \
  "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/datacenter-ecr:latest"
```

**Step 4 — Authenticated and pushed:**

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

docker push \
  "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/datacenter-ecr:latest"
```

**Step 5 — Created the ECS cluster:**

```bash
aws ecs create-cluster \
  --cluster-name datacenter-cluster \
  --capacity-providers FARGATE
```

**Step 6 — Created the task definition:**

```bash
cat > /tmp/task-definition.json << EOF
{
  "family": "datacenter-taskdefinition",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "datacenter-container",
    "image": "${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/datacenter-ecr:latest",
    "portMappings": [{"containerPort": 80, "hostPort": 80, "protocol": "tcp"}],
    "essential": true
  }]
}
EOF

aws ecs register-task-definition --cli-input-json file:///tmp/task-definition.json
```

**Step 7 — Created the service:**

```bash
aws ecs create-service \
  --cluster datacenter-cluster \
  --service-name datacenter-service \
  --task-definition datacenter-taskdefinition \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-04e57d87e9d3ef4bd,subnet-05b0526c43f6db0eb],securityGroups=[sg-0a4eee9d0346bcd03],assignPublicIp=ENABLED}"
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Subnet ID must match `subnet-[0-9a-f]+`**

My first `create-service` failed because I pasted placeholders from the documentation:

```
An error occurred (InvalidParameterException) when calling the CreateService operation: Subnet ID must match subnet-[0-9a-f]+
```

The strings `subnet-xxxxxxxxxxxxxxxxx` and `sg-xxxxxxxxxxxxxxxxx` aren't real IDs — they're placeholders in the shape of IDs. AWS validated them against the regex `subnet-[0-9a-f]+` and rejected them because `x` isn't hex.

**Fix:** Looked up real subnet and security group IDs from `describe-subnets` and `describe-security-groups`, then retried with actual values.

**Issue 2 — Service stuck at `Running: 0, Desired: 1` with an empty Events array**

First check after 60 seconds showed the service was `ACTIVE` but no task had started.

**Fix:** Waited another 60 seconds. The events field populated:

```
ECS was unable to assume the role 'arn:aws:iam::...:role/ecsTaskExecutionRole' that was provided for this task.
```

**Issue 3 — `ecsTaskExecutionRole` didn't exist**

```bash
aws iam get-role --role-name ecsTaskExecutionRole
# NoSuchEntity
```

The task definition referenced a role that the lab hadn't pre-created.

**Fix — created the role with the correct trust policy:**

```bash
cat > /tmp/ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ecs-tasks.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file:///tmp/ecs-trust-policy.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

**Issue 4 — Tried to `update-assume-role-policy` but got `AccessDenied`**

I incorrectly assumed the role had been created with the wrong trust policy and tried to update it. The `AccessDenied` was harmless — the role already had the correct policy. The `update` was unnecessary.

**Fix:** Recognized the role was created correctly. Used `update-service --force-new-deployment` to retry the deployment with the now-existing role.

**Step 8 — Verified the service was running:**

```bash
aws ecs describe-services \
  --cluster datacenter-cluster \
  --services datacenter-service \
  --query "services[0].{Running:runningCount,Desired:desiredCount,Events:events[0:3].message}" \
  --output json
```

Output:

```json
{
    "Running": 2,
    "Desired": 1,
    "Events": [
        "has started 1 tasks: (task ab5fd5a2c6864768a227e0133af34dbc).",
        "has reached a steady state.",
        "deployment completed."
    ]
}
```

`Running: 2` briefly shows during rollout — the old task and the new task overlapped. It settles to `1/1` within 60 seconds.

### Key Learning

**The full ECS deployment chain, in order:**

```
Dockerfile
    │
    ▼ docker build
Local image (datacenter-ecr:latest)
    │
    ▼ docker tag + push
ECR repository (datacenter-ecr)
    │
    ▼ referenced in task definition
ECS Task Definition (datacenter-taskdefinition)
    │
    ▼ deployed via service
ECS Service (datacenter-service)
    │
    ▼ runs on Fargate
Running task (with public IP)
```

Every link in this chain depends on the one before it. If ECR isn't authenticated, the push fails. If the task definition references the wrong image URI, the task can't pull. If the execution role is missing, the task never launches.

**The execution role is not optional — and it's separate from the task role.**

| Role | Purpose |
|---|---|
| **Execution role** (`ecsTaskExecutionRole`) | Lets the ECS agent pull from ECR, write to CloudWatch, read secrets |
| **Task role** | Grants the *application* inside the container permissions (e.g., S3 access) |

These are two different IAM roles, attached at two different points. The execution role is on the task definition. The task role is also on the task definition but assigned to the container at runtime. They're often confused.

**The `ecs-tasks.amazonaws.com` trust principal is critical.** If the trust policy points at `ec2.amazonaws.com`, the task can't assume the role — you get exactly the error I saw: *"unable to assume the role"*.

**Fargate requires specific CPU/memory combinations.** I used `256` CPU + `512` MiB memory, which is a valid Fargate pair. Arbitrary values (like `300` CPU) get rejected.

**Force a new deployment after fixing the role:**

```bash
aws ecs update-service \
  --cluster datacenter-cluster \
  --service datacenter-service \
  --force-new-deployment
```

This retries the task launch without recreating the service. Cheaper than `delete-service` + `create-service`.

---

## 3. Personal Task — Terraform

### Task: Attach an Existing IAM Policy to an Existing IAM User

I was tasked with attaching the already-existing policy `iampolicy_jim` to the already-existing user `iamuser_jim`.

### What I Did

**My first attempt used `resource` blocks** for both the user and the policy — as if I were creating them.

**The problem:** The task says "already exists." Terraform would try to **create** them and fail with `EntityAlreadyExists`.

**The fix — swapped both for `data` sources:**

```hcl
data "aws_iam_user" "user" {
  user_name = "iamuser_jim"
}

data "aws_iam_policy" "policy" {
  name = "iampolicy_jim"
}

resource "aws_iam_user_policy_attachment" "attachment" {
  user       = data.aws_iam_user.user.user_name
  policy_arn = data.aws_iam_policy.policy.arn
}
```

**Second problem — used the user's ARN instead of the username:**

```hcl
user = aws_iam_user.user.arn     # ❌
```

The `aws_iam_user_policy_attachment` resource's `user` argument expects the **username string**, not the ARN. Passing an ARN gets rejected by the AWS API (`NoSuchEntity`).

**Fix:** `user = data.aws_iam_user.user.user_name` — which resolves to `"iamuser_jim"`.

### Key Learning

**"Already exists" in a task description means use `data`, not `resource`.**

| Intent | Block type |
|---|---|
| Create a new resource | `resource` |
| Look up an existing resource | `data` |

`data` sources are **read-only**. They find the resource, expose its attributes, and never modify it. If you use `resource` on something that already exists, Terraform tries to create a duplicate and fails.

**Not every argument takes an ARN — even within the same service.**

This was the point I misunderstood today. I assumed "the policy uses ARN for everything." But:

| Resource | Argument | What it takes |
|---|---|---|
| `aws_iam_user_policy_attachment` | `user` | **username** string (`"iamuser_jim"`) |
| `aws_iam_user_policy_attachment` | `policy_arn` | policy **ARN** |
| `aws_iam_role_policy_attachment` | `role` | **role name** string |
| `aws_iam_group_policy_attachment` | `group` | **group name** string |
| `aws_iam_policy` | `name` | policy name (on create) |
| `data "aws_iam_policy"` | `name` or `arn` | either (lookup) |

The AWS API itself distinguishes: `AttachUserPolicy` takes `UserName` (string) and `PolicyArn` (ARN). Terraform mirrors the API — not an abstract "everything is an ARN" model.

**The corrected `main.tf` in one block:**

```hcl
data "aws_iam_user" "user" {
  user_name = "iamuser_jim"
}

data "aws_iam_policy" "policy" {
  name = "iampolicy_jim"
}

resource "aws_iam_user_policy_attachment" "attachment" {
  user       = data.aws_iam_user.user.user_name
  policy_arn = data.aws_iam_policy.policy.arn
}
```

**Verify with:**

```bash
aws iam list-attached-user-policies --user-name iamuser_jim
```

The `AttachedPolicies` array should contain `iampolicy_jim`.

---

## Key Takeaways

- 🐳 **`docker tag` creates a second name for the same image bytes.** No disk overhead. `docker tag <source> <target>` — the source is the existing image.
- ☁️ **ECS deployment is a chain:** Dockerfile → image → ECR → task definition → service → running task. Every link is required.
- 🎭 **The ECS execution role is separate from the task role.** Execution role pulls images and writes logs. Task role grants the application permissions.
- 🔑 **The execution role's trust policy must point at `ecs-tasks.amazonaws.com`** — not `ec2.amazonaws.com`.
- ⏳ **ECS Fargate requires valid CPU/memory pairs.** `256` + `512` is valid. Arbitrary values fail.
- 🔄 **`update-service --force-new-deployment` retries a task launch** without recreating the service — cheaper than delete + create.
- 📋 **"Already exists" in a task means use `data`, not `resource`.** Creating what already exists fails with `EntityAlreadyExists`.
- 🔍 **Not every argument takes an ARN.** `aws_iam_user_policy_attachment.user` takes a **username** string. `policy_arn` takes an ARN. The AWS API dictates the shape — not a general "everything is an ARN" rule.
- 🎯 **Read the API, not the assumption.** When Terraform's argument shape surprises you, check the AWS API's argument name (`UserName` vs `UserArn`).

---

## Day Status

| Area                                       | Status       |
| ------------------------------------------ | ------------ |
| 100 Days DevOps — Docker re-tag            | 🟢 Completed |
| 100 Days Cloud — ECS full deployment       | 🟢 Completed |
| Personal — Terraform IAM attachment        | 🟢 Completed |
| Docker (tagging)                           | 🟢 Reinforced |
| AWS (ECR, ECS, Fargate, execution role)    | 🟢 Learned   |
| Terraform (data sources, IAM attachment)   | 🟢 Completed |

**Overall: 🟢 Day 38/100 — Completed**

> **Major realization:** Today's two Terraform and ECS problems were the same mistake in different clothing — **assuming a shape instead of checking the shape.** I assumed the IAM attachment's `user` argument wanted an ARN (it wants a username). I assumed the ECS task definition's `executionRoleArn` pointed at a role that already existed (it didn't). Both errors came from "this seems like it should work" rather than "let me verify what this field actually accepts." The fix in both cases was trivial — swap `arn` for `user_name`, create the missing role. The lesson is the same as the whole week's: **the tool tells you the shape, not the assumption.** Read the API reference, run `describe-*` before assuming existence, and trust the error message over your mental model.
