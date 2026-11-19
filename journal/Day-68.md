# CloudOps / DevOps Journal

## Day 68 — 19 November 2026

**Challenges:** K8 L2 & Terraform L2

> **Context:** A day of exact-string precision. Deployed a multi-tier Guestbook application on Kubernetes and configured a complex S3 Lifecycle policy in Terraform. Both tasks failed initially due to tiny character mismatches and syntax shortcuts.

---

## 1. K8 L2 — Multi-Tier Guestbook Application

**Task:** Deploy a 3-tier app: Redis Master (1 replica), Redis Slave (2 replicas), and PHP Frontend (3 replicas), along with 4 services. The frontend image was pinned to a specific SHA256 digest.

### The Struggle
1.  **`InvalidImageName`:** The pods failed immediately. The SHA256 hash in the task description visually looked like 63 characters (one short of a valid 64-char SHA). 
2.  **The Wrong Workaround:** I tried using a tag instead (`gb-frontend:v5`). The pods started running, but the grader rejected it with: *"image for guestbook deployment is not 'gcr.io/google-samples/gb-frontend@sha256:...'"*.
3.  **The Fix:** Recounted the hash character by character. It **was** 64 characters. The copy-paste from the browser had likely dropped a character or inserted a hidden space. Rebuilt the manifest, verified the string length with `wc -c`, and applied.

```bash
# Verified the exact string length before applying
grep "gb-frontend" /tmp/guestbook.yaml | grep -oP 'sha256:\K[a-f0-9]+' | wc -c
# → 65 (64 hex chars + newline)
```

### Key Learning
**The grader checks the spec string, not the runtime status.** A pod can be `Running` with `:v5`, but the grader checks `.spec.template.spec.containers[0].image`. If it doesn't match `@sha256:a908...` exactly, you fail.
**`InvalidImageName` vs `ImagePullBackOff`:**
*   `InvalidImageName`: The string format is invalid (e.g., 63-char hash). K8s never contacts the registry.
*   `ImagePullBackOff`: The string is valid, but the image doesn't exist or auth failed.

---

## 2. Terraform L2 — S3 Lifecycle & Versioning

**Task:** Create a bucket (`datacenter-lifecycle-922692835`), enable versioning, and add a lifecycle rule (`datacenter-lifecycle-rule`) to transition to STANDARD_IA after 30 days and expire after 365 days.

### The Struggle
My initial code was a mix of real HCL and pseudocode:
```hcl
rule { 
    id; status; filter {}; expiration { 365 }; transition { days; storage_class } 
}
```
This isn't valid Terraform. HCL requires explicit `argument = value` assignments. Also, my rule `id` was set to the bucket name instead of `datacenter-lifecycle-rule`.

### The Fix
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "datacenter-lifecycle-rule" # Must match task exactly
    status = "Enabled"

    filter {
      prefix = ""                        # Fixed deprecated filter {}
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }
}
```

### Key Learning
**HCL has no shorthand.** You cannot write `expiration { 365 }`. It must be `expiration { days = 365 }`. Every block requires named arguments. This is the same class of error as writing `variable KKE_ami_id { variable = ... }` in a previous task.

**`filter {}` is deprecated.** In AWS provider v5+, an empty filter block triggers a warning because it's ambiguous. The modern way to say "apply to all objects" is `filter { prefix = "" }`.

**Watch the `id` field.** The task named the rule `datacenter-lifecycle-rule`. Using the bucket name as the rule ID will fail the grader's exact-match check.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 4 days |

---

## Key Takeaways
- 🐳 **`InvalidImageName` means the string is malformed.** Use `wc -c` to verify SHA256 hashes (must be 64 chars).
- 🐳 **The grader checks the exact spec string,** not whether the container is running.
- 🔧 **HCL blocks require named arguments** (`days = 365`), not positional values (`{ 365 }`).
- 🔧 **Use `filter { prefix = "" }`** instead of `filter {}` to apply lifecycle rules to all objects.
- 🔧 **Exact naming matters.** If the task names a rule, use that name for the `id`.

---

## Day Status
| Area | Status |
|---|---|
| K8 L2 — Guestbook Multi-Tier | 🟢 Completed |
| Terraform L2 — S3 Lifecycle | 🟢 Completed |

**Overall: 🟢 Day 68/100 — Completed**

> **Realization:** Today was a lesson in the difference between *approximate* and *exact*. A 63-character hash *looks* like a 64-character hash. A pseudocode block *looks* like Terraform. A bucket name used as a rule ID *looks* like a rule ID. But automated graders and the AWS API do not deal in approximations. They check the exact byte sequence. The final fix in both tasks wasn't about learning a new concept; it was about taking the time to verify the exact string before hitting apply. **The plan is only as good as the characters you type.**
