# CloudOps / DevOps Journal

## Day 39 — 21 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Create `news:devops` Image from Running Container `ubuntu_latest` on App Server 2

I was tasked with:

1. SSH into App Server 2
2. Take a running container `ubuntu_latest` and create a new image `news:devops` from it

### What I Did

**Step 1 — SSH into App Server 2:**

```bash
ssh steve@stapp02
sudo su -
```

**Step 2 — Confirmed the container was there:**

```bash
docker ps -a
```

Saw `ubuntu_latest` running.

**Step 3 — Committed the container to a new image:**

```bash
docker commit ubuntu_latest news:devops
```

**Step 4 — Verified:**

```bash
docker images
```

Saw `news:devops` alongside the base `ubuntu` image.

### Key Learning

**`docker commit` freezes the container's writable layer into a new image.** Everything changed since the container started — installed packages, edited files, new directories — becomes a new read-only layer stacked on top of the base image. The original `ubuntu_latest` container is untouched; you can keep it running or delete it.

**This is not the same as `docker tag`.** Yesterday I learned `docker tag` just creates a second *name* for the *same bytes* — no new image, no new layers. `docker commit` actually **creates a new image** with new content. Two commands that sound adjacent do completely different things.

**Volumes are not captured.** If the dev's changes were stored in a mounted volume, `docker commit` would miss them — volumes live outside the writable layer. Same for runtime config (CMD, ENTRYPOINT, env vars set at `run` time) unless you pass `--change` flags.

**This was the quick one.** No errors, no troubleshooting. But the concept clicked harder than the command did — commit is a *snapshot*, not a *build*. Which is why the industry moved to Dockerfiles. Commit is fine for a one-off backup; Dockerfiles are how you actually define an image.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: S3 Static Website Hosting via CLI

I was tasked with:

1. Create the bucket `xfusion-web-126083176`
2. Configure static website hosting with `index.html` as the index document
3. Allow public access
4. Upload `/root/index.html` to the bucket
5. Verify the S3 website URL works

### What I Did

**Step 1 — Created the bucket:**

```bash
aws s3api create-bucket --bucket xfusion-web-126083176 --region us-east-1
```

Returned:

```json
{
    "Location": "/xfusion-web-126083176",
    "BucketArn": "arn:aws:s3:::xfusion-web-126083176"
}
```

**Step 2 — Disabled the public-access block:**

A fresh bucket has all four blocks on. Public policy attachment fails until they're off.

```bash
aws s3api put-public-access-block \
  --bucket xfusion-web-126083176 \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

**Step 3 — Attached a public-read bucket policy:**

```bash
aws s3api put-bucket-policy --bucket xfusion-web-126083176 --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::xfusion-web-126083176/*"
  }]
}'
```

**Step 4 — Enabled website hosting:**

```bash
aws s3 website s3://xfusion-web-126083176/ --index-document index.html
```

**Step 5 — Uploaded `index.html` (first attempt — FAILED):**

```bash
aws s3 cp /root/index.html s3://xfusion-web-126083176/index.html \
  --content-type "text/html" \
  --acl public-read
```

```
upload failed: ./index.html to s3://xfusion-web-126083176/index.html
An error occurred (AccessControlListNotSupported) when calling the PutObject operation:
The bucket does not allow ACLs
```

**Step 6 — Dropped the `--acl` flag, re-ran, succeeded:**

```bash
aws s3 cp /root/index.html s3://xfusion-web-126083176/index.html \
  --content-type "text/html"
```

**Step 7 — Verified:**

```bash
aws s3api get-bucket-website --bucket xfusion-web-126083176
```

```json
{
    "IndexDocument": { "Suffix": "index.html" }
}
```

Hit the URL:

```bash
curl -I http://xfusion-web-126083176.s3-website-us-east-1.amazonaws.com
```

`200 OK`. Page rendered.

### Issues I Faced and How I Fixed It

**Issue 1 — `AccessControlListNotSupported` on upload**

The upload command carried `--acl public-read` — the "classic" way to make an object public. The bucket rejected it because **new S3 buckets in 2026 default to Object Ownership = Bucket owner enforced, which disables ACLs entirely**. Any request that tries to set an ACL fails with this exact error.

**Fix:** Removed `--acl public-read`. The bucket policy from Step 3 was already granting `s3:GetObject` to `Principal: "*"` on the whole bucket — the ACL was redundant.

```
What actually grants public read:   Bucket Policy (Principal: *, s3:GetObject) ✅
What I was trying to add:           Object ACL (--acl public-read)            ❌ disabled by default
```

**Issue 2 (near-miss) — `Resource` needing `/*`**

I almost wrote the bucket ARN without `/*`:

```json
"Resource": "arn:aws:s3:::xfusion-web-126083176"     ❌ read on the bucket, not the objects
"Resource": "arn:aws:s3:::xfusion-web-126083176/*"   ✅ read on objects inside
```

Without the `/*`, the website returns 403 on every object request. The bucket policy is what makes objects readable — but only if the resource pattern matches the objects.

### Key Learning

**AWS moved the access-control goalposts.** ACLs used to be how you made an S3 object public. Starting in 2023, new buckets default to **Bucket owner enforced**, meaning ACLs are disabled. The `--acl public-read` flag that appears in nearly every S3 tutorial **still runs, and still fails**, on modern buckets.

This is not a bug and it's not something to "fix." The fix is to **stop using ACLs**. Public access is now granted exclusively through bucket policies. The `--acl` flag is legacy muscle memory.

**The website endpoint is not the REST endpoint.** Two different URLs, two different protocols:

| Purpose | URL shape |
|---|---|
| Website (serves `index.html`, renders HTML) | `<bucket>.s3-website-<region>.amazonaws.com` |
| REST API (raw object access) | `<bucket>.s3.<region>.amazonaws.com/<key>` |

The website URL only works after `aws s3 website` has been run. Without website hosting configured, the website URL 404s.

**`aws s3api` vs `aws s3` are different tools for the same API.** `aws s3` is the high-level convenience layer (`cp`, `ls`, `mb`). `aws s3api` is the low-level API (`create-bucket`, `put-bucket-policy`, `get-bucket-website`). Every `aws s3` command is a wrapper around one or more `s3api` calls. The policy, ownership, and website configuration steps only exist at the `s3api` layer — there's no `aws s3 put-public-access-block`.

---

## 3. Personal Task — Terraform (L1 Tasks 28 & 29)

### Task 28: Enable Versioning on Pre-Existing Bucket `xfusion-s3-721473073`

### What I Did

The bucket already exists — it's not managed by this Terraform config. So no `aws_s3_bucket` resource; just point the versioning resource at the name:

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = "xfusion-s3-721473073"
  versioning_configuration {
    status = "Enabled"
  }
}
```

### Key Learning

**Versioning is its own resource in the modern AWS provider.** In older providers, `versioning { enabled = true }` was a block inside `aws_s3_bucket`. The provider split these into separate resources (`aws_s3_bucket_versioning`, `aws_s3_bucket_public_access_block`, `aws_s3_bucket_website_configuration`, etc.) so that each concern could be managed independently.

That means **you don't need to own the bucket to change one aspect of it.** `aws_s3_bucket_versioning` takes a bucket name (or ARN) and applies to whatever bucket that name refers to. It's fine if `aws_s3_bucket` isn't in your config. This is directly opposite to yesterday's lesson where "already exists" meant using `data` — because there the *whole* resource was already there. Here, only *one attribute* of the bucket is being set. The versioning config itself doesn't exist yet.

---

### Task 29: Backup and Delete Bucket `devops-bck-646496065` Using AWS CLI Through Terraform

### What I Did

**Step 1 — Wrote the `null_resource` with a `local-exec` provisioner:**

```hcl
resource "null_resource" "s3_backup_and_delete" {
  provisioner "local-exec" {
    command = "mkdir -p /opt/s3-backup/ && aws s3 cp s3://devops-bck-646496065 /opt/s3-backup/ --recursive && aws s3 rb s3://devops-bck-646496065 --force"
  }
}
```

**Step 2 — Applied:**

```bash
cd /home/bob/terraform
terraform init
terraform apply -auto-approve
```

**Step 3 — Verified:**

```bash
ls -la /opt/s3-backup/
aws s3 ls | grep devops-bck-646496065   # empty output — bucket gone
```

Both passed.

### Issues I Faced (and Thought About Before Running)

**Near-miss 1 — Almost used `aws s3 rm --recursive` to delete the bucket**

`aws s3 rm s3://bucket --recursive` **empties** the bucket but leaves the bucket itself in place. The task says the bucket must be **deleted**, not emptied.

**Fix:** Used `aws s3 rb s3://bucket --force` — this deletes the bucket **and** all its objects in one command. `--force` is the flag that allows `rb` on a non-empty bucket.

**Near-miss 2 — Almost forgot `mkdir -p /opt/s3-backup/`**

If `/opt/s3-backup/` doesn't exist, `aws s3 cp --recursive` fails with "No such file or directory." Chained `mkdir -p` at the front of the command with `&&`.

### Key Learning

**This was my first time using `local-exec` and a provisioner.** The concept finally landed: `local-exec` is Terraform *shelling out to the local machine*. It's not a Terraform resource — it's a hook on a resource that says "run this shell command."

The mechanics:

```
Terraform resource (normal):     Terraform ──► AWS API ──► creates bucket
local-exec provisioner:          Terraform ──► local shell ──► runs `aws s3 cp ...`
```

**`null_resource` is the carrier.** Provisioners can't stand alone — they have to hang off some resource. `null_resource` is a built-in resource that **does nothing** — creates no infrastructure. Its only purpose is to be a placeholder that provisioners can attach to. When there's nothing for Terraform to *create* (the bucket already exists, we just want to run commands), this is the move.

**`&&` is doing real work in the command.** It means "run the next command only if the previous one succeeded." If `mkdir` fails, `aws s3 cp` doesn't run. If `cp` fails, `aws s3 rb` doesn't run. If `aws s3 rb` fails, `terraform apply` fails too — Terraform treats a non-zero exit from a provisioner as a failed resource creation.

**Provisioners run at create time — once.** No `triggers` block means `null_resource` is considered "already created" on the next apply, so the command **won't run again**. For the lab, one run is enough. In production, this is why provisioners are considered a last resort — they don't model "run this every apply" cleanly without manual `triggers = { always = timestamp() }` hacks.

**`aws s3 rb --force` vs `aws s3 rm --recursive`** — the difference matters:

| Command | What it does |
|---|---|
| `aws s3 rm --recursive` | Deletes all objects in the bucket. Bucket stays. |
| `aws s3 rb --force` | Deletes all objects **and** the bucket itself. |

---

## Key Takeaways

- 🐳 **`docker commit` snapshots the writable layer into a new image.** Unlike `docker tag`, this *creates* an image. Volumes and runtime config are not captured.
- 🌐 **AWS buckets default to Bucket owner enforced in 2026 — ACLs are disabled.** `--acl public-read` fails with `AccessControlListNotSupported`. Use a bucket policy.
- 📜 **Public read comes from the bucket policy, not the ACL.** `Principal: "*"` + `s3:GetObject` + `Resource: ".../*"` — the `/*` is essential.
- 🔗 **Two URLs, two protocols.** Website URL (`s3-website-<region>.amazonaws.com`) serves HTML. REST URL (`s3.<region>.amazonaws.com/<key>`) is for API access only.
- 🎚️ **`aws s3` vs `aws s3api`:** high-level convenience wrapper vs low-level API. Policy, ownership, and website config only exist at `s3api`.
- 📦 **S3 versioning is now a separate resource (`aws_s3_bucket_versioning`)** — it takes a bucket name and applies to any bucket, owned or not.
- 🛠️ **`local-exec` = Terraform shelling out to the local machine.** First time using it — the mental model is "a resource that runs a command instead of creating infrastructure."
- 🎭 **`null_resource` is a provisioner carrier** — creates nothing, exists only so provisioners have something to attach to.
- 🔗 **`&&` in `local-exec` chains stop on first failure.** Terraform treats a non-zero exit as a resource creation failure.
- 🧹 **`aws s3 rb --force` deletes bucket + objects.** `aws s3 rm --recursive` only empties.

---

## Day Status

| Area                                        | Status       |
| ------------------------------------------- | ------------ |
| 100 Days DevOps — Docker commit             | 🟢 Completed |
| 100 Days Cloud — S3 static website          | 🟢 Completed |
| Personal — Terraform S3 versioning          | 🟢 Completed |
| Personal — Terraform local-exec             | 🟢 Completed |
| Docker (commit vs tag)                      | 🟢 Learned   |
| AWS (S3 policy, ownership, website)         | 🟢 Learned   |
| Terraform (versioning resource, provisioners)| 🟢 Learned   |

**Overall: 🟢 Day 39/100 — Completed**

> **Major realization:** Every task today came in two versions — and picking the wrong one was the source of every problem. Docker: `docker commit` (imperative snapshot) vs Dockerfile (declarative build) — I used the older one, and that's fine for a one-off, but I now understand why it's not the default. Terraform: native `aws_s3_bucket_versioning` resource vs `local-exec` shelling to CLI — the resource is preferred, the provisioner is an escape hatch. S3 access: bucket policy vs ACL — the policy is the current model, the ACL is deprecated-by-default. AWS CLI: `aws s3` (high-level) vs `aws s3api` (low-level) — the high-level wrapper covers the common cases, but policy and config work lives at the lower layer. Even the S3 deletion itself: `rm --recursive` vs `rb --force` — one empties, the other deletes. The pattern is not "always use the new way." It's **"know which layer you're on, because the tool's default has already moved past the one in the tutorial you remember."** Yesterday's lesson was *check the shape, not the assumption*. Today's is its sibling: *check which version of the world the tool is living in — because the flag that worked in 2022 is now the error message in 2026.*

