# CloudOps / DevOps Journal

## Day 28 — 10 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Cherry-Pick a Particular Commit on Git

I was tasked with cherry-picking a specific commit from one branch to another.

### What I Did

```bash
# Identify the commit hash to cherry-pick
git log --oneline

# Switch to the target branch
git checkout <target-branch>

# Cherry-pick the commit
git cherry-pick <commit-hash>
```

### Key Learning

**Cherry-pick is selective. Merge is inclusive.**

| Operation | What it does |
|---|---|
| `git merge` | Combines **entire branches** — brings all commits from one branch into another |
| `git cherry-pick` | Applies **one specific commit** from anywhere onto your current branch |

**Why it’s called cherry-pick:**  
You’re literally picking one commit (the cherry) out of a branch and placing it onto another branch. You don’t take the whole branch — just the one commit you want.

**How it works:**  
Cherry-pick takes the changes from the chosen commit and creates a **new commit** with the same changes on your current branch. The original commit stays where it was.

**When to use it:**
- You need a hotfix from one branch but not the rest of that branch’s work.
- You accidentally committed to the wrong branch and want to move just that commit.
- You want a specific change without merging an entire feature branch.

**No issues faced.**  
This reinforced my understanding of Git history manipulation and how cherry-pick differs from merge.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Private ECR Repository and Push a Docker Image

I was tasked with:

1. Create a private Amazon ECR repository named `xfusion-ecr`
2. Build a Docker image from a Dockerfile located at `/root/pyapp` on the `aws-client` host
3. Push the image to the ECR repository with the tag `latest`

### What I Did

**Step 1 — Created the ECR repository:**

```bash
REPO_ID=$(aws ecr create-repository \
  --repository-name xfusion-ecr \
  --query "repository.registryId" \
  --output text)
```

**Step 2 — Built the Docker image (first attempt — wrong):**

```bash
cd /root/pyapp
docker build -t app:latest < Dockerfile
```

**Error:** `requirements.txt not found`

**Root cause:**  
The `< Dockerfile` syntax sends **only the Dockerfile** as the build context. The Dockerfile likely had a `COPY requirements.txt .` or `RUN pip install -r requirements.txt` instruction, but `requirements.txt` was not included in the context. Docker couldn’t find it.

**Correct build command:**

```bash
docker build -t app:latest .
```

The `.` means “use the current directory as the build context” — so Docker sees the Dockerfile **and** all other files in `/root/pyapp`, including `requirements.txt`.

**Step 3 — Authenticated Docker to ECR:**

```bash
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.<region>.amazonaws.com
```

**Step 4 — Tagged the image for ECR:**

```bash
docker tag app:latest \
  <account-id>.dkr.ecr.<region>.amazonaws.com/xfusion-ecr:latest
```

**Step 5 — Pushed the image:**

```bash
docker push \
  <account-id>.dkr.ecr.<region>.amazonaws.com/xfusion-ecr:latest
```

### Issues I Faced and How I Fixed Them

**Issue 1 — Docker build context error**

Using `docker build -t app:latest < Dockerfile` only passed the Dockerfile as context. The fix was to use `docker build -t app:latest .` from within `/root/pyapp`.

**Issue 2 — Tagging and pushing**

I initially struggled with the correct ECR image URI format. The pattern is:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
```

Once I tagged the local image with that full URI and authenticated Docker to ECR, the push succeeded.

### Key Learning

**Docker build context matters.**  
`docker build .` sends the entire current directory to the Docker daemon. `docker build < Dockerfile` sends only the Dockerfile. Always use `.` unless you have a specific reason to limit the context.

**ECR push workflow is always the same:**

1. Create repository
2. Authenticate Docker to ECR
3. Build image locally
4. Tag image with full ECR URI
5. Push image

**`--query` and variables make CLI work cleaner.**  
Using `REPO_ID=$(aws ecr create-repository ... --query "repository.registryId" --output text)` taught me to capture values and reuse them instead of copying manually.

**Note:** `registryId` is the AWS account ID. The full repository URI is available via `repository.repositoryUri`. For most tasks, you need the URI, not just the registry ID.

---

## Key Takeaways

- 🌿 **Cherry-pick is selective; merge is inclusive.** Cherry-pick applies one commit; merge brings an entire branch.
- 🐳 **Docker build context is critical.** `docker build .` includes everything in the directory. `< Dockerfile` includes only the Dockerfile — usually the wrong choice.
- ☁️ **ECR push workflow:** create repo → authenticate → build → tag → push.
- 🔑 **Tagging for ECR requires the full URI:** `<account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`.
- 🧩 **Variables and `--query` make AWS CLI more efficient and scriptable.**
- 🎯 **Docker and AWS work together.** Docker builds the image; ECR stores it. This is a core containerized deployment pattern.

---

## Day Status

| Area                            | Status       |
| ------------------------------- | ------------ |
| 100 Days DevOps — Git cherry-pick | 🟢 Completed |
| 100 Days Cloud — AWS ECR + Docker push | 🟢 Completed |
| Git (cherry-pick)               | 🟢 Learned   |
| AWS (ECR)                       | 🟢 Completed |
| Docker (build context, tag, push) | 🟢 Reinforced |
| **Ansible L2**                  | 🟢 Previously completed |

**Overall: 🟢 Day 28/100 — Completed**

> **Major realization:** Cherry-pick and merge look similar but solve different problems — one is surgical, the other is wholesale. And Docker’s build context is not a detail you can ignore: `docker build .` vs `docker build < Dockerfile` is the difference between a working image and a `requirements.txt not found` error. Understanding *why* the command works the way it does prevents silent failures.
