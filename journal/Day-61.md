# CloudOps / DevOps Journal

## Day 61 — 12 November 2026

**Challenges:** K8 L2 (Storage & Troubleshooting)

> **Context:** Focused heavily on Kubernetes storage (Persistent Volumes) and a repeat of the Redis troubleshooting task. Solved a tricky 502 Bad Gateway caused by missing labels, and peeled back the layers of a multi-bug Redis deployment.

---

## 1. K8 L2 — PersistentVolume, PVC, Pod, and Service

**Task:** Create a `hostPath` PV (`pv-datacenter`), a matching PVC (`pvc-datacenter`), a pod (`pod-datacenter`) using `httpd:latest` mounted to the document root, and a NodePort service (`web-datacenter`) on 30008.

**The Manifest Structure:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-datacenter
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/finance
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-datacenter
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-datacenter
  labels:
    app: pod-datacenter
spec:
  containers:
    - name: container-datacenter
      image: httpd:latest
      volumeMounts:
        - name: pv-storage
          mountPath: /usr/local/apache2/htdocs
  volumes:
    - name: pv-storage
      persistentVolumeClaim:
        claimName: pvc-datacenter
---
apiVersion: v1
kind: Service
metadata:
  name: web-datacenter
spec:
  type: NodePort
  selector:
    app: pod-datacenter
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30008
EOF
```

### Issues Faced and How I Fixed Them

**Issue: 502 Bad Gateway on the App button.**
The Pod was Running, but the App button returned 502.
*   *Diagnostic:* `kubectl get endpoints web-datacenter` returned `<none>`.
*   *Root Cause:* I forgot to put `labels: app: pod-datacenter` in the Pod's `metadata` block. The Service was looking for a label that didn't exist.
*   *Fix:* Deleted the pod and re-applied it with the correct labels. Endpoints populated immediately.

### Key Learning
**Persistent Volumes are a two-step binding process.** The PV is the actual storage (`5Gi`), and the PVC is the request (`2Gi`). They only bind if their `storageClassName` matches (in this case, `manual`) and the PV has enough capacity to satisfy the PVC. 
**Also:** The document root for the official `httpd` image is `/usr/local/apache2/htdocs`, not `/var/www/html`.

---

## 2. K8 L2 — Troubleshoot Redis Deployment

**Task:** Fix the broken `redis-deployment`. Pods were not in a Running state.

**The Diagnosis (Two Bugs):**
This task had a cascading failure. Fixing the first bug revealed a second bug hiding underneath.

1.  **Bug 1 (The Mount):** `kubectl describe pod` showed `MountVolume.SetUp failed... configmap "redis-conig" not found`. The deployment had a typo.
    *   *Fix:* `kubectl patch deployment redis-deployment --type=json -p='[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/name","value":"redis-config"}]'`
2.  **Bug 2 (The Image):** Once the mount was fixed, the new pod crashed with `ImagePullBackOff`. The YAML had an invalid image tag.
    *   *Fix:* `kubectl set image deployment/redis-deployment *=redis:alpine`
3.  **Cleanup:** The old broken ReplicaSet and stuck pods were blocking the rollout.
    *   *Fix:* `kubectl delete pods -l app=redis --force --grace-period=0` and deleted the old RS.

### Key Learning
**Kubernetes troubleshooting is like peeling an onion.** The `ContainerCreating` state masked the image problem because the Pod couldn't even get to the image pull phase while the volume was failing. **Fix one layer, and the next layer reveals itself.** Always re-run `kubectl get pods` and `kubectl describe` after every fix.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 | 🟢 In Progress |
| **100 Days DevOps** | Ongoing | K8 Block |
| **Terraform L2** | Paused at 5/20 | Resumes later |

---

## Key Takeaways
- 🐳 **PV and PVC must share the same `storageClassName`** (e.g., `manual`) and the PV must be larger than the PVC request.
- 🐳 **The `httpd` document root is `/usr/local/apache2/htdocs`.**
- 🐳 **Forgetting `metadata.labels` on a Pod breaks Service routing (502 Bad Gateway).**
- 🐳 **Fix one bug, find another.** A broken volume mount will hide an image pull error.
- 🐳 **Force-deleting stuck pods** is necessary to unblock a broken rollout.

---

## Day Status
| Area | Status |
|---|---|
| K8 L2 — PV/PVC/Pod/Service | 🟢 Completed |
| K8 L2 — Redis Troubleshooting | 🟢 Completed |

**Overall: 🟢 Day 61/100 — Completed**

> **Realization:** Today's tasks were a masterclass in Kubernetes state. The PV/PVC task taught me that storage is an explicit binding contract (StorageClass + Capacity + AccessMode). The Redis task taught me that a Pod's status is just the topmost symptom of a deeper stack of dependencies. If the volume is broken, the container can't even try to pull the image. You have to fix the foundation before you can see the cracks in the walls above it.
