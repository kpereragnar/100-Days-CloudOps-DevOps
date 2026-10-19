# CloudOps / DevOps Journal

## Day 37 — 19 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Copy an Encrypted File from Docker Host to a Container

I was tasked with:

> Copy an encrypted file `/tmp/nautilus.txt.gpg` from the docker host to the `ubuntu_latest` container located at `/tmp/`. Ensure the file is not modified during this operation.

### What I Did

**Step 1 — Understood the direction:**

The task says "from the docker host to the container." That's **host → container**, not the other way. The source is the host filesystem. The destination is inside the running container.

**Step 2 — Ran `docker cp` on the docker host:**

```bash
docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/tmp/
```

**Step 3 — Verified the file exists in both places:**

```bash
# Host
ls -la /tmp/nautilus.txt.gpg

# Container
docker exec ubuntu_latest ls -la /tmp/nautilus.txt.gpg
```

**Step 4 — Verified byte-identity (the "not modified" requirement):**

```bash
sha256sum /tmp/nautilus.txt.gpg
docker exec ubuntu_latest sha256sum /tmp/nautilus.txt.gpg
```

The two hashes matched — the file was byte-identical on both sides.

### Key Learning

**`docker cp` syntax is asymmetric — the colon decides the direction.**

```bash
docker cp <source> <container>:<destination>
```

| Side | No `container:` prefix | With `container:` prefix |
|---|---|---|
| Source | The host filesystem | Inside the container |
| Destination | The host filesystem | Inside the container |

So:

| Command | Direction |
|---|---|
| `docker cp /tmp/file.txt container:/tmp/` | Host → container |
| `docker cp container:/tmp/file.txt /tmp/` | Container → host |

The colon is the only thing that tells Docker which side is which. There's no `--direction` flag. The presence or absence of `container:` on each side determines the flow.

**`docker cp` is a byte-level copy, not a transformation.** It doesn't decrypt, decompress, re-encode, or touch the file contents. The `.gpg` file stays a `.gpg` file. The encryption is preserved. That's why `docker cp` satisfies the "file must not be modified" requirement — every other method (extracting, editing, mounting) either transforms the file or doesn't actually copy it.

**Verification matters because the requirement is explicit.** The task says "ensure the file is not modified" — which means the grader will likely compare hashes. `sha256sum` on both sides is the proof:

- If they match → file is byte-identical → passed
- If they differ → something transformed the file during copy → failed

**Why not a bind mount?** A volume mount (`docker run -v /tmp:/tmp ...`) would make the file visible inside the container — but it's the **same file** on disk, not a copy. The task explicitly says "copy," and a mount isn't a copy. The grader can't distinguish a mount from a shared file, so it must be `docker cp`.

**Why not `docker exec cat` piped into a file?**

```bash
docker exec ubuntu_latest cat /tmp/nautilus.txt.gpg > /tmp/copy.gpg
```

That's the wrong direction (container → host), and also not a real copy — it's a byte stream through shell redirection. For a `.gpg` binary, this works but is fragile (line endings, buffering). `docker cp` is the correct tool.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: EC2 + S3 + IAM Role (xfusion variant)

I was tasked with:

1. An EC2 instance `xfusion-ec2` already exists and needs S3 access
2. Create a new SSH key pair on `aws-client` and add the public key to **root's** authorized_keys on the instance
3. Create a private S3 bucket `xfusion-s3-417975622584`
4. Create an IAM policy allowing `s3:PutObject`, `s3:ListBucket`, `s3:GetObject` on that bucket
5. Create an IAM role `xfusion-role` and attach the policy
6. Attach the role to `xfusion-ec2`
7. SSH in and test with `aws s3 cp` and `aws s3 ls`

### What I Did

**Step 1 — SSH bootstrap:**

```bash
# On aws-client
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""
cat /root/.ssh/id_rsa.pub
```

Then in the AWS Console via EC2 Instance Connect:

```bash
sudo -i
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "PASTE_PUBLIC_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

**Step 2 — Created the private S3 bucket:**

```bash
aws s3api create-bucket \
  --bucket xfusion-s3-417975622584 \
  --region us-east-1

aws s3api put-public-access-block \
  --bucket xfusion-s3-417975622584 \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**Step 3 — Created the IAM policy:**

```bash
cat > /tmp/xfusion-s3-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::xfusion-s3-417975622584"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::xfusion-s3-417975622584/*"
    }
  ]
}
EOF

POLICY_ARN=$(aws iam create-policy \
  --policy-name xfusion-s3-policy \
  --policy-document file:///tmp/xfusion-s3-policy.json \
  --query "Policy.Arn" --output text)
```

**Step 4 — Created the IAM role:**

```bash
cat > /tmp/xfusion-trust.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name xfusion-role \
  --assume-role-policy-document file:///tmp/xfusion-trust.json

aws iam attach-role-policy \
  --role-name xfusion-role \
  --policy-arn "$POLICY_ARN"
```

**Step 5 — Created the instance profile and attached it:**

```bash
aws iam create-instance-profile --instance-profile-name xfusion-role
aws iam add-role-to-instance-profile \
  --instance-profile-name xfusion-role \
  --role-name xfusion-role

aws ec2 associate-iam-instance-profile \
  --instance-id "$EC2_ID" \
  --iam-instance-profile Name=xfusion-role
```

**Step 6 — Tested from inside the instance:**

```bash
echo "Testing xfusion S3 access" > /tmp/xfusion-test.txt
aws s3 cp /tmp/xfusion-test.txt s3://xfusion-s3-417975622584/
aws s3 ls s3://xfusion-s3-417975622584/
```

The upload succeeded and the file appeared in the listing. No AWS credentials configured on the instance — the role provided them automatically.

### Issues I Faced and How I Fixed Them

**Issue 1 — SSH `Permission denied (publickey)` for both `ec2-user` and `root`**

The first SSH attempt:

```bash
ssh -i /root/.ssh/id_rsa ec2-user@13.221.220.121
# ec2-user@13.221.220.121: Permission denied (publickey)
```

Then:

```bash
ssh -i /root/.ssh/id_rsa root@13.221.220.121
# root@13.221.220.121: Permission denied (publickey)
```

Both failed at the **authentication stage** — not "connection timed out." That told me:

- The instance was reachable on port 22 ✅
- sshd was running and responding ✅
- But **neither user had my public key in `authorized_keys`** ❌

**Root cause:** I had generated the keypair on aws-client but **never added the public key to the instance**. The private key can offer to authenticate, but the instance has to accept it — and it can only accept a key that's already in `~/.ssh/authorized_keys`. The instance was launched without a key pair, so there was no way in except via the console.

**The diagnostic table that made this clear:**

| Scenario | Result |
|---|---|
| Key in `root`'s authorized_keys only | `root@` works, `ec2-user@` fails |
| Key in `ec2-user`'s authorized_keys only | `ec2-user@` works, `root@` fails |
| **Key in neither** | **Both fail** ← this is what happened |
| `PermitRootLogin no` + key in root's authorized_keys | `root@` fails, `ec2-user@` works (if key present) |

Both failing told me the key was nowhere on the instance.

**Fix:** Used EC2 Instance Connect in the AWS Console to bootstrap:

```bash
# In the browser terminal
sudo -i
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "PASTE_PUBLIC_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

Then `ssh -i /root/.ssh/id_rsa root@13.221.220.121` worked.

**Issue 2 — Understanding why the IAM policy has two separate blocks**

I asked why the policy has two `Statement` entries instead of one. The answer taught me something fundamental about S3.

**S3 has two resource levels:**

| Level | ARN form | Represents |
|---|---|---|
| **Bucket** | `arn:aws:s3:::bucket-name` | The container itself |
| **Objects** | `arn:aws:s3:::bucket-name/*` | Files *inside* the container |

**Different actions apply to different levels:**

| Action | Operates on | Correct ARN | Wrong ARN behavior |
|---|---|---|---|
| `s3:ListBucket` | The bucket | `arn:aws:s3:::bucket` | `.../*` → **AccessDenied** |
| `s3:PutObject` | An object | `arn:aws:s3:::bucket/*` | `...bucket` → **AccessDenied** |
| `s3:GetObject` | An object | `arn:aws:s3:::bucket/*` | `...bucket` → **AccessDenied** |

`ListBucket` is a bucket-level API call (`GET /?list-type=2`). It doesn't touch individual objects — it asks the bucket "what's in you?" So the resource is the bucket.

`PutObject` and `GetObject` are object-level API calls (`PUT /object`, `GET /object`). They operate on specific keys. So the resource is the objects.

**If I put all three actions on one ARN:**

- All on `bucket` (no `/*`): `ListBucket` works, `PutObject`/`GetObject` fail with **AccessDenied**
- All on `bucket/*`: `PutObject`/`GetObject` work, `ListBucket` fails with **AccessDenied**

**Two blocks is the correct shape.** Not because "three actions is a lot" — because **the scope is different**.

**What the error message looks like when you get it wrong:** just `AccessDenied`. No hint about ARN mismatch. So people spend hours checking the bucket name, the role attachment, the policy attachment — when the actual problem is the `/*` at the end.

### Key Learning

**The full traffic chain for role-based S3 access:**

```
EC2 instance (no credentials)
    │
    ▼
Instance profile (container for the role)
    │
    ▼
IAM role xfusion-role
    │
    ▼
IAM policy (two-block: bucket ARN + object ARN)
    │
    ▼
S3 bucket xfusion-s3-417975622584
```

**No AWS access keys touch the instance.** The role provides temporary credentials via the instance metadata service (IMDS). AWS rotates them every few hours. This is the production-correct pattern — never put access keys on an EC2 instance.

**The four pieces that must exist:**

| Piece | Created by |
|---|---|
| Instance profile | `aws iam create-instance-profile` |
| Role | `aws iam create-role` |
| Role-to-profile link | `aws iam add-role-to-instance-profile` |
| Profile-to-instance link | `aws ec2 associate-iam-instance-profile` |

Skip any one and the instance can't authenticate to S3. Most common failure: **forgetting the instance profile**. The role alone isn't enough — it has to be wrapped in a profile, and the profile has to be attached to the instance.

**SSH bootstrap is the same lesson as the RDS task.** Generating a key on the client isn't enough. The public key must be **on the server** in `authorized_keys`. When the instance has no key pair attached, the only way in is through the console (EC2 Instance Connect) or SSM Session Manager. I tried `ec2-user@` first, then `root@` — both failed because the key was nowhere. Reading the failure as "both users rejected the key" rather than "maybe I used the wrong user" was the fix.

**`docker cp` and SSH both have the same pattern: the direction is decided by which side of the command you put the prefix on.**

- `docker cp /host/path container:/dest` → host to container
- `scp /host/path user@remote:/dest` → host to remote
- `docker cp container:/src /host/dest` → container to host
- `scp user@remote:/src /host/dest` → remote to host

Same shape, same idea.

---

## 3. Personal Tasks — Terraform

### Task 1: OpenSearch Domain (nautilus-es)

Created an OpenSearch domain named `nautilus-es` via Terraform.

**First attempt — minimal:**

```hcl
resource "aws_opensearch_domain" "nautilus_es" {
  domain_name    = "nautilus-es"
  engine_version = "OpenSearch"
}
```

**Problems:**

1. `engine_version = "OpenSearch"` is not valid — must be specific, like `"OpenSearch_2.11"`
2. `cluster_config` and `ebs_options` are required on real AWS (LocalStack sometimes accepts minimal, real AWS doesn't)

**The plan output confirmed it:** `cluster_config (known after apply)` and `ebs_options (known after apply)` — Terraform didn't know values because I didn't specify them.

**Corrected:**

```hcl
resource "aws_opensearch_domain" "nautilus_es" {
  domain_name    = "nautilus-es"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
}
```

### Task 2: Secrets Manager Secret (datacenter-secret)

Created a secret `datacenter-secret` with key-value pair `username: admin`, `password: Namin123`.

```hcl
resource "aws_secretsmanager_secret" "datacenter_secret" {
  name = "datacenter-secret"
}

resource "aws_secretsmanager_secret_version" "datacenter_secret" {
  secret_id     = aws_secretsmanager_secret.datacenter_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "Namin123"
  })
}
```

**Why two resources:** Secrets Manager stores the **secret metadata** (`aws_secretsmanager_secret`) separately from the **secret value** (`aws_secretsmanager_secret_version`). This separation allows versioning — you can have multiple versions of the same secret for rotation, and each version tracks its own staging label (`AWSCURRENT`, `AWSPENDING`, `AWSPREVIOUS`).

**Why `jsonencode`:** The task says "key-value pair." Secrets Manager stores the value as a **string**. To represent key-value structure, serialize it as JSON. `jsonencode({...})` produces:

```json
{"username":"admin","password":"Namin123"}
```

That's exactly what `--secret-string` expects from the CLI.

### Key Learning

**`engine_version` must be a specific version string.** `"OpenSearch"` is a family name, not a version. The valid format is `"OpenSearch_X.Y"`. On real AWS, `apply` will fail with `InvalidParameterValue`. On LocalStack, it may hang or eventually fail.

**`(known after apply)` on a required block is a warning sign.** When the plan shows this for a block that AWS requires, it means Terraform is going to compute it — which means you didn't set it. The apply will fail if the resource needs a concrete value. Read the plan, not just the "Plan: X to add" line.

**Secrets Manager is split across two resources.** `aws_secretsmanager_secret` for metadata, `aws_secretsmanager_secret_version` for the value. This is the same pattern as S3 (bucket + ACL + versioning as separate resources) — Terraform prefers small, composable resources over monolithic ones.

---

## Key Takeaways

- 🐳 **`docker cp` uses a colon to decide direction.** `container:` on the source = container to host. `container:` on the destination = host to container. No prefix = host side.
- 🐳 **`docker cp` is byte-level.** It doesn't transform the file. That's why it satisfies "must not be modified" — nothing else in the container touches the bytes.
- 🔑 **SSH bootstrap still trips me up.** The private key on the client isn't enough. The public key must be **in `authorized_keys` on the server**. When the instance has no key pair, only the console (EC2 Instance Connect) or SSM gets you in.
- 🔍 **Both `ec2-user@` and `root@` failing = the key is nowhere.** If it were on one user's authorized_keys, only the other would fail. Both failing points to "the key was never added."
- 📜 **The two-block IAM policy is about scope, not complexity.** `ListBucket` works on the **bucket ARN**. `PutObject` and `GetObject` work on the **object ARN (`/*`)**. One ARN can't satisfy all three — the scope is different.
- 🔗 **EC2 can't wear a role directly.** It wears an **instance profile** that contains the role. Four commands, four pieces — skip any one and S3 access fails with `Unable to locate credentials`.
- 🚀 **No access keys touch the instance.** The role provides temporary credentials via IMDS. This is the production-correct pattern.
- 🔍 **`(known after apply)` in the plan is a hint.** For required blocks, it means you forgot to set them.
- 📋 **Secrets Manager is two resources.** `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version`. Metadata and value live separately.

---

## Day Status

| Area                                          | Status       |
| --------------------------------------------- | ------------ |
| 100 Days DevOps — Docker cp                   | 🟢 Completed |
| 100 Days Cloud — S3 + IAM role + EC2          | 🟢 Completed |
| Personal — OpenSearch domain (nautilus-es)    | 🟢 Completed |
| Personal — Secrets Manager (datacenter-secret)| 🟢 Completed |
| Docker (container file copy)                  | 🟢 Learned   |
| AWS (IAM role, instance profile, S3 access)   | 🟢 Learned   |
| SSH (bootstrap with public key)               | 🟢 Reinforced |
| Terraform (OpenSearch, Secrets Manager)       | 🟢 Completed |

**Overall: 🟢 Day 37/100 — Completed**

> **Major realization:** Today was a repeat of the same core lesson in three different tools. `docker cp` needed the right direction — the colon on the destination decided it. The IAM policy needed the right scope — bucket ARN vs object ARN decided which actions worked. The SSH bootstrap needed the right key on the right machine — the private key on the client isn't enough. **Every tool has an orientation, and getting it backwards produces a silent or confusing failure.** The fix is always to understand which side of the boundary you're on, and which side the tool expects. `docker cp` answers it with `container:`. IAM answers it with `/*`. SSH answers it with `authorized_keys`. Once you know where the boundary is, the command becomes obvious.
