---

# CloudOps / DevOps Journal

## Day 54 — 5 November 2026

**Challenges:** 100 Days DevOps & K8 L1 (Final Push)

> **Context:** The final sprint to clear the K8 L1 track. Completed 4 tasks today: the 100 Days DevOps task, the final sidecar troubleshooting task from yesterday, and the last 3 K8 L1 tasks. **K8 L1 is officially complete.**

---

## 1. 100 Days DevOps — Resolve VolumeMounts Issue (`nginx-phpfpm`)

**Task:** Fix the `nginx-phpfpm` pod, copy `index.php`, and make the website accessible.

**The Fixes:**
1.  **The Volume Mount:** `kubectl describe pod` showed the `nginx-container` was mounting the shared volume at `/usr/share/nginx/html`, while the ConfigMap and PHP-FPM were using `/var/www/html`. Nginx couldn't see the PHP files. 
    *   *Fix:* Recreated the pod, changing Nginx's `mountPath` to `/var/www/html`.
2.  **The 502 Bad Gateway:** The Service (`nginx-service`) had zero endpoints because the recreated pod lost its labels. The Service selector was `app=php-app`.
    *   *Fix:* `kubectl label pod nginx-phpfpm app=php-app`
3.  **The Copy:** `kubectl cp /home/thor/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container`

### Key Learning
**A 502 Bad Gateway in K8s almost always means the Service has zero endpoints.** `kubectl get endpoints <svc>` is the fastest diagnostic. When you delete and recreate a Pod, you lose its labels. You must re-apply them to reconnect the Service.

---

## 2. K8 L1 — Troubleshooting `webserver` Pod (Sidecar Victory)

**Task:** Fix the `webserver` pod (nginx + ubuntu sidecar) and make the website accessible.

**The Fix:**
The KodeKloud grader rejected the native `initContainers` sidecar approach. It specifically wanted the sidecar in the standard `spec.containers` array, kept alive with a long-running command, AND it needed the `app=web-app` label to fix the 502 Bad Gateway.

```yaml
spec:
  containers:
    - name: nginx-container
      image: nginx:latest
    - name: sidecar-container
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "tail -f /dev/null"]
```

### Key Learning
**Real-world K8s vs. Grader Logic.** In the real world, K8s 1.28+ uses `initContainers` with `restartPolicy: Always` for sidecars. But the automated grader was written for older logic and literally checks `spec.containers[1].name`. Sometimes you have to write the older, standard architecture to pass the test. 

---

## 3. K8 L1 Task 12 — Update Deployment and Service

**Task:** Modify `nginx-deployment` and `nginx-service` without deleting them. Scale 1 → 5, image `1.18` → `latest`, NodePort `30008` → `32165`.

**Commands:**
```bash
kubectl scale deployment nginx-deployment --replicas=5
kubectl set image deployment/nginx-deployment *=nginx:latest
kubectl patch svc nginx-service -p '{"spec":{"ports":[{"port":80,"nodePort":32165}]}}'
```

### Key Learning
**Imperative updates save time.** You don't need to edit YAML files to update a deployment. `kubectl scale` handles replicas, `kubectl set image` handles rolling updates (the `*=` wildcard updates all containers), and `kubectl patch` applies JSON changes directly to the live object.

---

## 4. K8 L1 Task 13 — Expose ReplicaSet via NodePort Service

**Task:** Create `httpd-service` (NodePort 30080) for `httpd-replicaset` (labels `app: httpd_app`, `type: front-end`).

**The Fix:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: httpd-service
spec:
  type: NodePort
  selector:
    app: httpd_app
    type: front-end
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

### Key Learning
**The Service `selector` must match the Pod labels exactly.** If the Service has `app: httpd_app` but the pods are missing the `type: front-end` label, the Service will silently fail to route traffic (Endpoints = `<none>`).

---

## 5. K8 L1 Task 14 — Resolve VolumeMounts Issue (Final Task!)

**Task:** Same as the 100 Days task—fix `nginx-phpfpm`, copy `index.php`, make the website work.

**The Fix:**
Used the exact same manifest fix as the 100 Days task earlier today, but this time, I included the `labels: app: php-app` directly in the YAML metadata from the start. This prevented the 502 Bad Gateway entirely.

```bash
kubectl delete pod nginx-phpfpm
# Apply fixed YAML with correct mountPath and labels
kubectl cp /home/thor/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container
```

### Key Learning
**Experience compounds.** Having solved this exact issue earlier in the day for the 100 Days track, I knew the three layers (Volume Mount, Label Patch, File Copy) and executed them in one pass. 

---

## 🎉 Milestone: K8 L1 Complete

14/14 tasks finished. The sidecar and volume-mount tasks were the hardest of the track, but they forced me to understand how K8s handles pod lifecycles and service routing.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 5 | ✅ **Completed** |
| **K8 L1 Assessment** | Tomorrow (Nov 6) | **Scheduled** |
| **Codomax Internship** | Saturday (Nov 7) | PrestaShop deployment |
| **K8 L2** | Sunday (Nov 8) | Starts |
| **Terraform L2** | Paused at 5/20 | Resumes after K8 L2 or alternates |

---

## Key Takeaways

- 🐳 **A 502 Bad Gateway means empty Service endpoints.** Check `kubectl get endpoints <svc>`.
- 🐳 **Deleting a Pod deletes its labels.** You must re-apply them to reconnect the Service.
- 🐳 **`kubectl scale`, `kubectl set image`, and `kubectl patch`** let you update live resources without deleting them.
- 🐳 **Service selectors must match Pod labels exactly.** Missing one label breaks the routing.
- 🐳 **Grader logic vs. real-world logic.** Native sidecars (`initContainers`) are modern, but the grader wanted standard containers (`tail -f /dev/null`).
- 🎓 **K8 L1 is finished.** 14 tasks, multiple debugging rabbit holes, and a mountain of YAML.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — VolumeMounts | 🟢 Completed |
| K8 L1 — Sidecar Troubleshooting | 🟢 Completed |
| K8 L1 — Update Deployment/Service | 🟢 Completed |
| K8 L1 — Expose ReplicaSet | 🟢 Completed |
| K8 L1 — VolumeMounts (Task 14) | 🟢 Completed |

**Overall: 🟢 Day 54/100 — Completed · K8 L1 Certified**

> **Realization:** Today was the ultimate test of reading error messages and understanding the layers of Kubernetes. The `nginx-phpfpm` task looked like an application error, but it was a volume mount issue. The `webserver` task looked like a pod crash, but it was a missing command. The 502 error looked like a networking issue, but it was a missing label.
>
> K8 L1 is officially done. Tomorrow is the assessment, Saturday is the Codomax internship deployment, and Sunday we start K8 L2. The pace is relentless, but the foundation is solid.
