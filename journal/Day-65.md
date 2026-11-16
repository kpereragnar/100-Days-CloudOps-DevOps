Here is the journal entry for today (Day 65). It captures the K8 troubleshooting, the Terraform S3 migration, and the intense laptop optimization session. 

---

# CloudOps / DevOps Journal

## Day 65 — 16 November 2026

**Challenges:** 100 Days DevOps (K8 block), Terraform L2, and Host OS Optimization

> **Context:** A heavy technical day spanning three distinct layers: fixing a broken Kubernetes app deployment, navigating Terraform state complexities during an S3 data migration, and resolving severe I/O disk thrashing on the host laptop caused by VM overcommitment.

---

## 1. 100 Days DevOps — Troubleshoot Python App Deployment

**Task:** The `python-deployment-nautilus` app is not coming up. Fix the deployment and service so it is accessible on NodePort `32345`.

**The Diagnosis:**
The deployment and service were already deployed but had two deliberate misconfigurations:
1.  **Deployment:** The image was `poroko/flask-app-demo`. The correct image is `poroko/flask-demo-app` (words `app` and `demo` swapped). The pod was stuck in `ImagePullBackOff`.
2.  **Service:** The service was named `python-service-nautilus`. Its `targetPort` was set to `8080`. However, the Python Flask app defaults to port `5000`.

**The Fix:**
```bash
# Fix the image
kubectl set image deployment/python-deployment-nautilus python-container-nautilus=poroko/flask-demo-app

# Patch the service to use the correct Flask targetPort
kubectl patch svc python-service-nautilus -p '{"spec":{"ports":[{"port":8080,"targetPort":5000,"nodePort":32345,"protocol":"TCP"}]}}'
```

**Verification:**
```bash
kubectl get pods -l app=python_app
# → 1/1 Running

kubectl get endpoints python-service-nautilus
# → 10.244.x.x:5000 (Service correctly routed to the pod)

curl -I http://localhost:32345
# → HTTP/1.1 200 OK
```

### Key Learning
**Never assume the targetPort based on the service port.** The service `port` was 8080, which is a common default. But the Flask app inside the container was listening on 5000. If the `targetPort` doesn't match what the container is actually listening on, the endpoints will populate, but traffic will be dropped. 

---

## 2. Terraform L2 — S3 Bucket Data Migration

**Task:** Create a new private bucket `nautilus-sync-300847721` and migrate all data from the existing `nautilus-s3-300847721` bucket.

**The Battle (Three Attempts):**

**Attempt 1: `aws_s3_object_copy` (Failed)**
Tried using a `for_each` loop over `data.aws_s3_objects` to copy files. 
*   *Failure:* The source bucket resource label was missing from the config, causing a dependency error. Then, after adding it, only *some* files migrated. 
*   *Root Cause:* `aws_s3_object_copy` silently fails on files with special characters (spaces, `+`, `#`) in their keys.

**Attempt 2: The Ghost Bucket (Failed)**
Switched to a `null_resource` running `aws s3 sync`. However, the source bucket was labeled `wordpress_bucket` in the existing state, but the code was updated to call it `source_bucket`. 
*   *Failure:* Terraform saw the label change as a "destroy the old bucket, create a new one" operation. It tried to delete the source bucket (`BucketNotEmpty` error) and recreate it (`BucketAlreadyExists` error).

**Attempt 3: The Successful Sync (Passed)**
Reverted the resource label back to `wordpress_bucket` to match the state. Kept the `null_resource` for the sync operation.

**The Final Code Snippet:**
```hcl
# Source bucket label kept exactly as it was in state
resource "aws_s3_bucket" "wordpress_bucket" {
  bucket = "nautilus-s3-300847721"
}

# Destination bucket
resource "aws_s3_bucket" "new_bucket" {
  bucket = var.KKE_BUCKET
}

# Migration via CLI using local-exec provisioner
resource "null_resource" "s3_sync" {
  triggers = {
    source      = aws_s3_bucket.wordpress_bucket.id
    destination = aws_s3_bucket.new_bucket.id
  }

  provisioner "local-exec" {
    command = "aws s3 sync s3://${aws_s3_bucket.wordpress_bucket.id} s3://${aws_s3_bucket.new_bucket.id}"
  }
}
```

### Key Learning
**Terraform resource labels are immutable identifiers.** If you change `aws_s3_bucket.source` to `aws_s3_bucket.destination` in your code, Terraform doesn't see a name change; it sees a plan to destroy the old resource and create a new one. To rename a resource without destroying it, you must use `terraform state mv` or a `moved {}` block.

**`aws s3 sync` is the right tool for bulk data migration.** Pure Terraform resource blocks (`aws_s3_object_copy`) are fine for 3-4 files, but they have edge cases with encoding and pagination. The AWS CLI handles all of this natively and idempotently. Using `local-exec` is the correct pattern when the operation is a bulk data transfer, not an infrastructure creation.

---

## 3. Host OS Optimization — Resolving Disk Thrashing

**Issue:** The laptop was constantly hanging. Disk usage was pegged at 100%, System Interrupts CPU usage was at 15%, and memory commit was at 20GB out of 16GB physical.

**The Diagnosis & Fix:**
1.  **RAM Overcommitment:** Three Windows VMs were "paused" (still holding 4GB each = 12GB), and Kali Linux was running with 8GB. This is 20GB allocated on a 16GB host.
2.  **Disk Thrashing (I/O Wait):** Because physical RAM was full, Windows aggressively used the Pagefile (hard drive). The disk hit 100% utilization just swapping data. This caused VLC to take 5 minutes to open a local file and File Explorer to hang.
3.  **The Fix:** 
    *   Fully shut down the paused VMs (suspending frees the RAM, pausing does not).
    *   Reduced the Kali VM's RAM from 8GB to 4GB.
    *   Restarted the host to clear the Pagefile cache.
    *   Result: Memory commitment dropped to a healthy 7GB/20GB, and disk usage fell from 100% to 10%.

### Key Learning
**Paused VMs still reserve host RAM.** In hypervisors (VMware, VirtualBox), pausing a VM freezes the CPU but keeps the RAM locked. To release the RAM, you must Suspend (save to disk) or Power Off.

**Overcommitting resources causes cascading failures.** When RAM runs out, the OS uses the disk. When the disk is maxed out, the CPU enters "I/O Wait" (System Interrupts). This is the exact same failure mode as a Kubernetes node running out of memory, or an AWS EC2 instance exhausting its EBS burst balance.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 7 days |

---

## Key Takeaways
- 🐳 **Flask apps default to port 5000.** Don't assume 8080 or 80 when configuring the `targetPort`.
- 🔧 **Terraform resource labels are state identifiers.** Changing them triggers a destroy/recreate cycle.
- 🔧 **`aws s3 sync` via `local-exec`** is the reliable way to migrate bulk data in Terraform.
- 💻 **Paused VMs eat RAM.** Suspend or power off VMs to free resources and prevent Pagefile thrashing.
- 💻 **High "System Interrupts" + 100% Disk = I/O Wait.** Your CPU is waiting for the hard drive to catch up.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Python App | 🟢 Completed |
| Terraform L2 — S3 Migration | 🟢 Completed (after 3 attempts) |
| Laptop Optimization | 🟢 Resolved |

**Overall: 🟢 Day 65/100 — Completed**

> **Realization:** Today was a perfect storm of resource management. On the laptop, overcommitting RAM caused Disk I/O to choke the CPU. In Kubernetes, mismatching the `targetPort` caused the Service to route traffic to a dead end. In Terraform, changing a resource label caused the state to try and destroy infrastructure that was still in use. 
> 
> Whether you are allocating memory to a VM, configuring ports for a container, or managing state for IaC, the underlying principle is the same: **the system only knows what you explicitly declare, and it will enforce the limits you set.** If you declare 20GB of VMs on a 16GB host, the system will thrash. If you declare a targetPort of 8080 for an app listening on 5000, the system will drop traffic. If you declare a new resource label, the system will try to rebuild it. The fix is always to align your declaration with reality.
