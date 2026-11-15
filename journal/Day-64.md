Here is the journal entry for today (Day 64). It captures the K8 Iron Gallery stack and the intense three-attempt battle with the Kinesis Terraform task.

---

# CloudOps / DevOps Journal

## Day 64 — 15 November 2026

**Challenges:** 100 Days DevOps (K8 block) & Terraform L2

> **Context:** Cleared the Iron Gallery Kubernetes deployment and fought through a brutal Terraform Kinesis task that failed twice due to LocalStack quirks and state drift before finally passing.

---

## 1. 100 Days DevOps — Iron Gallery App Deployment (K8)

**Task:** Deploy the Iron Gallery stack (frontend + MariaDB) under the `iron-namespace-nautilus` namespace.

**The Fix:**
Deployed two separate Deployments and two Services via a single YAML manifest.
*   **Gallery:** `kodekloud/irongallery:2.0` (NodePort 32678, label `run: iron-gallery`). Mounted `emptyDir` volumes at `/data` and `/uploads`.
*   **Database:** `kodekloud/irondb:2.0` (ClusterIP 3306, label `db: mariadb`). Set env vars (`MYSQL_DATABASE=database_host`).

**Verification:**
```bash
kubectl get pods -n iron-namespace-nautilus
# → Both pods 1/1 Running

kubectl get endpoints iron-db-service-nautilus -n iron-namespace-nautilus
# → 10.244.x.x:3306 (Service found the DB pod)
```

### Key Learning
**Label matching is the difference between a working app and a 502 Bad Gateway.** The gallery uses `run: iron-gallery` while the DB uses `db: mariadb`. When writing multiple Deployments and Services in one manifest, it's dangerously easy to mix up the selectors. Verifying the `endpoints` for both services ensures the traffic routing is wired correctly.

---

## 2. Terraform L2 — Kinesis Data Stream & CloudWatch Alarm

**Task:** Create a Kinesis Data Stream (`datacenter-kinesis-stream`), enable shard-level metrics, and create a CloudWatch alarm (`datacenter-kinesis-alarm`) for `WriteProvisionedThroughputExceeded` > 1.

### The Three-Attempt Battle

**Attempt 1: Race Condition**
Ran `terraform apply`. It completed successfully. I hit "Check" on KodeKloud, and it failed. 
*   *Root Cause:* Kinesis takes 30–60 seconds to transition from `CREATING` to `ACTIVE`. Terraform's apply returns as soon as the API accepts the request, but the grader checks the live state immediately. It saw `CREATING` and rejected it.

**Attempt 2: The LocalStack Tag Drift**
Added a wait loop to ensure Kinesis was `ACTIVE` before submitting. It showed `ACTIVE`, but the grader rejected it again with: *"Terraform plan is still showing pending changes."*
*   *Root Cause:* I had added `tags = { Name = "..." }` to both resources. The lab runs on LocalStack (mock AWS, account `000000000000`). LocalStack has a known bug where tags on Kinesis/CloudWatch don't persist. So `terraform apply` finished, but `terraform plan` immediately showed `+ tags` as a pending change.

**Attempt 3: The Clean Run**
Removed all `tags` from the Terraform code. Ran `terraform apply`. Ran `terraform plan` → **"No changes. Your infrastructure matches the configuration."** Waited for Kinesis to be `ACTIVE`. Checked the outputs (lowercase `kke_`). Hit Check. **Passed.**

### Key Learning

**The grader's contract is the `terraform plan` output, not just the resource existence.** KodeKloud's newer Terraform graders run a `plan` check before accepting. If there is *any* drift, it fails, even if the resources are technically running in AWS.

**Mock AWS vs. Real AWS.** In production AWS, adding tags is best practice. In LocalStack (KodeKloud's lab environment), tags on Kinesis and CloudWatch frequently fail to persist. When working in a mock environment, **strip optional metadata (tags, descriptions)** if the grader complains about pending changes.

**Race conditions apply to Terraform too.** Just like Day 38's ECS task and Day 46's EKS cluster, Terraform returning "Creation complete" does not mean the resource is ready. Always loop until the AWS CLI shows the resource is `ACTIVE`.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 8 days |

---

## Key Takeaways
- 🐳 **Double-check label selectors** when deploying multi-tier apps. `kubectl get endpoints` proves the wiring.
- 🔧 **LocalStack doesn't like tags.** Remove optional `tags` blocks if the Terraform grader fails on "pending changes."
- 🔧 **Wait for `ACTIVE` state** on streaming/database resources before hitting Check. Terraform apply returning is not enough.
- 🔧 **The golden rule of KodeKloud Terraform:** Always run `terraform plan` manually and confirm `No changes` before submitting.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Iron Gallery | 🟢 Completed |
| Terraform L2 — Kinesis & CloudWatch | 🟢 Completed (after 3 attempts) |

**Overall: 🟢 Day 64/100 — Completed**

> **Realization:** Today was a perfect storm of cloud and Terraform quirks. The K8 app taught me that routing (labels/endpoints) is just as important as the pod running. But the Kinesis task taught the harder lesson: **in infrastructure as code, the tool's definition of "done" is `No changes`, not "the API call succeeded."** The two failed attempts on Kinesis weren't because the infrastructure was wrong; they were because the *state* wasn't clean. A real engineer doesn't just make it work; they make it idempotent.
