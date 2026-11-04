# CloudOps / DevOps Journal

## Day 52 — 3 November 2026

**Challenges:** 100 Days Cloud (AWS), K8 L1, and AWS Ops

> **Context:** 100 Days of Cloud (AWS) Certification achieved. K8 L1 tasks continued. Also tackled an EBS volume resize on EC2.

---

## 1. 🎓 Milestone: 100 Days of Cloud (AWS) Certified

**Task:** Complete the KodeKloud 100 Days of Cloud (AWS) program.

I officially completed the AWS track and received my completion certificate. 

### Key Learning

**The 100 Days of Cloud program is actually a split track: 50 days of AWS, 50 days of Azure.** 

I made the strategic decision to stop at the AWS milestone. I am choosing to build depth in a single cloud provider rather than spreading myself thin across two. 

**The certificate proves consistency.** 50 days of labs, 50 journal entries, and dozens of broken resources. The value isn't the PDF — it's the debugging reflex built over those 50 days.

---

## 2. AWS Ops — EBS Volume Resize (8 GiB → 12 GiB)

**Task:** Expand the root volume of `devops-ec2` from 8 GiB to 12 GiB and reflect the change in the filesystem.

**Commands (aws-client):**
```bash
# Identify volume
VOLUME_ID=$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$INSTANCE_ID" --query "Volumes[0].VolumeId" --output text)

# Modify EBS size
aws ec2 modify-volume --volume-id $VOLUME_ID --size 12

# Wait for modification to complete
aws ec2 describe-volumes-modifications --volume-ids $VOLUME_ID
```

**Commands (inside the instance):**
```bash
sudo growpart /dev/xvda 1
# ❌ FAILED: resize2fs: Bad magic number in super-block
sudo resize2fs /dev/xvda1

# ✅ FIXED: Filesystem is XFS, not ext4
sudo xfs_growfs /
```

### Issues Faced and How I Fixed Them

**Issue 1 — SSH `Permission denied`**
Tried to SSH as `ubuntu@` but it failed. The instance was actually running Amazon Linux 2023, not Ubuntu.
**Fix:** Switched to `ec2-user@`.

**Issue 2 — `resize2fs` failed with `Bad magic number`**
The partition grew (`lsblk` showed 12G), but `df -h /` stayed at 8G. `resize2fs` only works on ext2/3/4 filesystems.
**Fix:** Amazon Linux uses XFS. The correct command to grow an XFS filesystem online is `sudo xfs_growfs /`.

### Key Learning

**Resizing a volume is a 3-layer process:** 
1. **EBS Volume** (`aws ec2 modify-volume`)
2. **Partition** (`growpart /dev/xvda 1`)
3. **Filesystem** (`resize2fs` for ext4, `xfs_growfs` for XFS)

**`df -h` shows the filesystem; `lsblk` shows the partition.** When `df` is smaller than `lsblk`, the filesystem hasn't grown. If `resize2fs` fails, it's because you are on XFS, not ext4.

---

## 3. K8 L1 — Rolling Update `nginx:1.18`

**Task:** Update `nginx-deployment` to image `nginx:1.18`.

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.18
kubectl rollout status deployment/nginx-deployment
```

### Key Learning

**`kubectl set image` syntax:** `deployment/<name> <container-name>=<new-image>`. It triggers a rolling update automatically, creating a new ReplicaSet and terminating the old pods gracefully.

---

## 4. K8 L1 — ReplicaSet `httpd-replicaset`

**Task:** Create a ReplicaSet with 4 replicas, `httpd:latest`, labels `app: httpd_app`, `type: front-end`.

**First attempt failed:** The grader rejected it with `Labels 'app' is not set to 'httpd_app'`.

**The fix:**
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: httpd-replicaset
  labels:                  # ← THIS WAS MISSING. Labels must be on the ReplicaSet object itself.
    app: httpd_app
    type: front-end
spec:
  replicas: 4
  selector:
    matchLabels:
      app: httpd_app
      type: front-end
  template:
    metadata:
      labels:
        app: httpd_app
        type: front-end
    spec:
      containers:
        - name: httpd-container
          image: httpd:latest
```

### Key Learning

**Labels must be applied at the top level (`metadata.labels`) AND the pod template level (`spec.template.metadata.labels`).** The selector is the bridge between the two. If you only label the pods, the ReplicaSet itself remains unlabeled and fails the grader.

---

## 5. K8 L1 — CronJob `devops`

**Task:** CronJob `devops`, schedule `*/2 * * * *`, container `cron-devops`, image `httpd:latest`, command `echo Welcome to xfusioncorp!`, restart policy `OnFailure`.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: devops
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cron-devops
              image: httpd:latest
              command: ["/bin/sh", "-c", "echo Welcome to xfusioncorp!"]
          restartPolicy: OnFailure
```

### Key Learning

**CronJobs have a 3-level nesting structure:**
`CronJob` → `jobTemplate` → `template` (Pod) → `spec`.

**`restartPolicy: OnFailure` goes on the Pod spec, not the CronJob spec.** Since the `echo` command exits immediately with code 0, the pod will show as `Completed`, not `Running`. That is expected.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ **Certified** |
| **K8 L1** | 9/14 tasks done | Finish ~Nov 6 |
| **Terraform L2** | Paused at 5/20 | Resumes Nov 8 |
| **Projects** | 22 Nov | On track |

---

## Key Takeaways

- ☁️ **100 Days Cloud (AWS) completed.** Strategically skipped the Azure half to focus on AWS depth.
- ☁️ **EBS resize requires 3 steps:** Volume → Partition (`growpart`) → Filesystem (`resize2fs` for ext4, `xfs_growfs` for XFS).
- ☁️ **Amazon Linux uses `ec2-user`, not `ubuntu`.** Read the instance AMI when SSH fails.
- 🐳 **ReplicaSet labels go in `metadata.labels`, not just the Pod template.**
- 🐳 **CronJob `restartPolicy` belongs in the nested Pod template**, not the top-level spec.
- 🐳 **`kubectl set image`** is the imperative way to trigger a rolling update.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days Cloud (AWS) Certification | 🟢 Completed |
| AWS Ops — EBS Resize | 🟢 Completed |
| K8 L1 — Rolling Update | 🟢 Completed |
| K8 L1 — ReplicaSet | 🟢 Completed (after fix) |
| K8 L1 — CronJob | 🟢 Completed |

**Overall: 🟢 Day 52/100 — Completed · 100 Days Cloud (AWS) Certified**

> **Realization:** Today marks a major milestone with the 100 Days Cloud certification. The decision to skip the Azure half isn't about doing less—it's about doing *better*. The goal right now is depth. 
> 
> The technical lessons today were all about **layers**. The EBS volume needed three layers resized (EBS, partition, filesystem). The ReplicaSet needed labels on two layers (the object, and the pod). The CronJob needed the restart policy nested three layers deep. 
> 
> **In Kubernetes and AWS, missing a layer doesn't always throw a loud error.** Sometimes it just silently fails to be recognized by the grader, or it grows the disk but not the filesystem. The fix is always to verify *every* layer independently. `lsblk` vs `df`, `get rs --show-labels` vs `get pods --show-labels`. **The tool shows you what's there; you have to check that all layers agree.**
