---

# CloudOps / DevOps Journal

## Day 55 — 6 November 2026

**Challenges:** 100 Days DevOps & K8 L1 Assessment

> **Context:** Completed the daily 100 Days DevOps task, and then took the K8 L1 Assessment. **Scored 99% and officially passed the Kubernetes L1 track.**

---

## 1. 100 Days DevOps — Shared Volume Pod (`volume-share-datacenter`)

**Task:** Create a Pod `volume-share-datacenter` with two `ubuntu:latest` containers, both running a sleep command. Mount `emptyDir` volume `volume-share` at `/tmp/ecommerce` (container 1) and `/tmp/demo` (container 2). Write a file in container 1, verify it exists in container 2.

**YAML:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-datacenter
spec:
  volumes:
    - name: volume-share
      emptyDir: {}
  containers:
    - name: volume-container-datacenter-1
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "sleep infinity"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/ecommerce
    - name: volume-container-datacenter-2
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "sleep infinity"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/demo
```

**Verification:**
```bash
# Create file in container 1
kubectl exec volume-share-datacenter -c volume-container-datacenter-1 -- sh -c 'echo "Welcome to xFusionCorp Industries" > /tmp/ecommerce/ecommerce.txt'

# Read file from container 2
kubectl exec volume-share-datacenter -c volume-container-datacenter-2 -- cat /tmp/demo/ecommerce.txt
# → Welcome to xFusionCorp Industries
```

### Key Learning
**`emptyDir` volumes are shared at the Pod level, not the container level.** Even though the containers mount the volume at different paths (`/tmp/ecommerce` vs `/tmp/demo`), they point to the exact same underlying storage on the node. Writing a file in one instantly makes it visible in the other. 
**`sleep infinity` is the standard keep-alive.** Without it, the `ubuntu` containers would exit immediately, and the Pod would never reach `2/2 Running`.

---

## 2. 🏆 K8 L1 Assessment — 99% Passed

**Score:** 99% (9/10 passed) · **Passing score:** 70% · **Time taken:** ~45 minutes

### What the 10 Questions Covered

It was a live cluster exam. No multiple choice. Each question was a task.

| Q | Task | Status |
|---|---|---|
| Q1 | Pod with an init container (`red-nautilus-t1q5`) | ❌ Failed (see below) |
| Q2 | Basic Pod creation with labels (`httpd-test-t1q4`) | ✅ |
| Q3 | Update Deployment image & Service NodePort (`nginx-deployment1-t2q3`) | ✅ |
| Q4 | Scale Deployment (`blue-app-t2q5`) | ✅ |
| Q5 | Create Namespace (`dev-t3q3`) | ✅ |
| Q6 | Create ReplicaSet with Labels (`httpd-replicaset-t3q4`) | ✅ |
| Q7 | Troubleshoot Sidecar (`webserver-t4q1`) | ✅ |
| Q8 | Troubleshoot Service (fix ClusterIP → NodePort) (`purple-app-deployment-t4q5`) | ✅ |
| Q9 | Update Service NodePort (`service-t5q3`) | ✅ |
| Q10 | Create ClusterIP Service with specific ports (`deployment-svc-t5q2`) | ✅ |

### The Q1 Failure: `command` vs `args`

**The manifest I submitted:**
```yaml
command: ['/bin/bash', '-c']
args: ['sleep 1000']
```

**Why it failed:** The grader checked the `command` field and saw `['/bin/bash', '-c']`. It wanted to see the whole string `['/bin/bash', '-c', 'sleep 1000']` inside the `command` array. 

**The lesson:** KodeKloud graders use strict regex matching. Unless the prompt explicitly says "Command: X, Arguments: Y", put everything into the `command` array. K8s merges them at runtime anyway.

### The Hardest Questions (and how I solved them)

**Q8 — Troubleshoot Service `purple-app-deployment-t4q5`:**
The service was stuck as `ClusterIP` and wasn't routing. I had to patch it to `NodePort`, set the NodePort to `32232`, and ensure the selector matched the deployment's label (`app=purple-app-t4q5`). One `kubectl patch` command did all three.

**Q10 — Create ClusterIP Service `deployment-svc-t5q2`:**
I created it perfectly (`port: 8090`, `targetPort: 80`), but the endpoints were `<none>`. The deployment had no top-level labels, but the *pods* had `app=app-t5q2`. Once I patched the Service selector to match the pod labels, the endpoints populated.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ **Assessment Passed (99%)** |
| **K8 L1 Certificate** | Pending | Should generate on dashboard |
| **100 Days DevOps** | Ongoing | Daily tasks |
| **Codomax Internship** | Saturday | Planned |
| **K8 L2** | Sunday | Planned |
| **Terraform L2** | Paused at 5/20 | Resumes later |

---

## Key Takeaways

- 🐳 **`emptyDir` shares storage at the Pod level.** Different mount paths, same underlying bytes.
- 🐳 **Grader strictness on `command` vs `args`.** Put the whole command in the `command` array unless the task explicitly separates them.
- 🐳 **Patching Services requires knowing the exact port structure.** Using JSON patch (`--type='json'`) is safer than merge patch for changing NodePorts.
- 🐳 **Always check `kubectl get pods --show-labels`** when a Service has `<none>` endpoints. The service selector must match the pod labels, not the deployment labels.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Volume Share | 🟢 Completed |
| K8 L1 Assessment | 🟢 **Passed (99%)** |

**Overall: 🟢 Day 55/100 — Completed · K8 L1 Certified**

> **Realization:** The K8 L1 assessment wasn't about memorizing commands. It was about reading the task, knowing which object to build, and troubleshooting the broken ones. The only failure (Q1) was a format mismatch, not a knowledge gap. The 99% proves that the debugging sessions over the last week—the 502 Bad Gateways, the missing labels, the broken volume mounts—actually stuck.
