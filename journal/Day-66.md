# CloudOps / DevOps Journal

## Day 66 — 17 November 2026

**Challenges:** K8 L2 & Terraform L2

> **Context:** A dual-track day focused on configuration management. Deployed a Redis cache with injected configuration in Kubernetes, and created an S3 bucket with strict lifecycle protections in Terraform.

---

## 1. K8 L2 — Redis Deployment with ConfigMap

**Task:** Deploy `redis-deployment` (1 replica, `redis:alpine`, container `redis-container`, 1 CPU request, port 6379). Mount an `emptyDir` at `/redis-master-data` and a ConfigMap (`my-redis-config`) at `/redis-master`. The ConfigMap must contain `maxmemory 2mb` in a key named `redis-config`.

**The Fix:**
Created a two-resource YAML manifest.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-redis-config
data:
  redis-config: |
    maxmemory 2mb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis-container
          image: redis:alpine
          ports:
            - containerPort: 6379
          resources:
            requests:
              cpu: "1"
          volumeMounts:
            - name: data
              mountPath: /redis-master-data
            - name: redis-config
              mountPath: /redis-master
      volumes:
        - name: data
          emptyDir: {}
        - name: redis-config
          configMap:
            name: my-redis-config
```

**Verification:**
```bash
kubectl get deploy redis-deployment
# → 1/1 Running

kubectl exec deploy/redis-deployment -- cat /redis-master/redis-config
# → maxmemory 2mb
```

### Key Learning
**ConfigMap keys become filenames.** The key `redis-config` inside the `data` block becomes a file named `redis-config` when mounted as a volume. The container sees `/redis-master/redis-config`. 
**`cpu: "1"` requires quotes.** In YAML, `1` is an integer, but Kubernetes expects a CPU quantity string. Without quotes, the apply might fail validation. 

---

## 2. Terraform L2 — S3 Bucket with `prevent_destroy`

**Task:** Create `nautilus-s3-200701799` with `prevent_destroy` lifecycle rule. Use `variables.tf` (`KKE_BUCKET_NAME`), `terraform.tfvars`, and `outputs.tf` (`s3_bucket_name`).

**The Fix:**
My initial attempt had three errors:
1. I put `prevent_destroy = true` directly inside the `resource` block instead of the `lifecycle` block.
2. I tried to set a `variable` default to a resource reference (`default = aws_s3_bucket.bucket.id`), which is invalid.
3. I hardcoded the bucket name instead of using `terraform.tfvars`.

**Corrected Files:**

```hcl
# variables.tf
variable "KKE_BUCKET_NAME" {
  type = string
}

# terraform.tfvars
KKE_BUCKET_NAME = "nautilus-s3-200701799"

# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.KKE_BUCKET_NAME

  lifecycle {
    prevent_destroy = true
  }
}

# outputs.tf
output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.id
}
```

**Verification:**
I ran `terraform destroy` intentionally to test the protection. Terraform correctly refused:
```
Error: Instance cannot be destroyed
Resource aws_s3_bucket.bucket has lifecycle.prevent_destroy set...
```

### Key Learning
**`prevent_destroy` is a `lifecycle` meta-argument.** It goes inside a `lifecycle {}` block, not directly in the resource block. This applies to every Terraform resource.

**Variables are inputs, not outputs.** A `variable` block cannot reference a resource attribute (like `aws_s3_bucket.bucket.id`). If you want a dynamic default, you can't have one. You either hardcode a literal default or leave it empty and supply it via `terraform.tfvars` (which is exactly what this task required).

**Terraform's lifecycle rules are strict.** When `prevent_destroy` is set, `terraform destroy` and `terraform apply` (if it would remove the resource) will both fail. This is a critical production safety net to prevent accidental deletion of stateful resources like databases or state buckets.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 6 days |

---

## Key Takeaways
- 🐳 **ConfigMap `data` keys become files** when mounted as a volume.
- 🐳 **Kubernetes CPU requests need string values** (e.g., `"1"` or `"1000m"`), not integers.
- 🔧 **`prevent_destroy` must be inside a `lifecycle` block.**
- 🔧 **Variables cannot reference resources.** They are inputs.
- 🔧 **`terraform.tfvars` is auto-loaded** and is the cleanest way to supply values without hardcoding defaults.

---

## Day Status
| Area | Status |
|---|---|
| K8 L2 — Redis Deployment | 🟢 Completed |
| Terraform L2 — S3 prevent_destroy | 🟢 Completed |

**Overall: 🟢 Day 66/100 — Completed**

> **Realization:** Both tasks today highlighted the importance of *separating configuration from the resource*. In Kubernetes, the ConfigMap decouples the Redis memory limit from the Deployment spec. In Terraform, the `terraform.tfvars` file decouples the bucket name from the resource block. And in both cases, the tool enforces strict rules to protect state: Kubernetes won't mount a file if the ConfigMap key is wrong, and Terraform won't delete a bucket if `prevent_destroy` is set. The tool's rules are rigid; our job is to align with them.
