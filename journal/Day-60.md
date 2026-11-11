# CloudOps / DevOps Journal

## Day 60 — 11 November 2026

**Challenges:** 100 Days DevOps & K8 L2

> **Context:** Massive Kubernetes sprint today. Cleared 6 tasks across the K8 L2 track and the daily 100 Days DevOps curriculum. The focus was heavily on Deployments, Services, Rollouts, and Troubleshooting.

---

## 1. 100 Days DevOps & K8 L2 — Grafana Deployment (The 502 Fix)

**Task:** Deploy Grafana and expose it on NodePort 32000.

**The Fix:**
We knew from yesterday that the KodeKloud "App" button expects the Service to be on port 80. I created the deployment with Grafana's internal port `3000`, but mapped the Service `port: 80` to `targetPort: 3000`.

```yaml
# Service snippet
ports:
  - port: 80
    targetPort: 3000
    nodePort: 32000
```

### Key Learning
**The KodeKloud reverse proxy looks for Port 80.** If you expose your app on 3000, 8080, etc., the App button will throw a 502, even if `curl` works perfectly from the jump-host. Always map `port: 80` to your app's `targetPort`.

---

## 2. K8 L2 — Troubleshoot Redis (`redis-deployment`)

**Task:** Fix the broken `redis-deployment` where pods were stuck in `ContainerCreating`.

**The Diagnosis & Fixes (Two Bugs):**
1.  **Bug 1 (The Mount):** `kubectl describe pod` showed a `FailedMount` because the deployment referenced a ConfigMap named `redis-conig` (typo), but the cluster had `redis-config`.
    *   *Fix:* Patched the deployment volume to point to the correct name: `kubectl patch deployment redis-deployment --type=json -p='[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/name","value":"redis-config"}]'`
2.  **Bug 2 (The Image):** Once the mount was fixed, the new pod crashed with `ImagePullBackOff`. The original YAML had a bad image tag.
    *   *Fix:* `kubectl set image deployment/redis-deployment *=redis:alpine`
3.  **Cleanup:** The old stuck ReplicaSet was blocking the rollout. Used `kubectl delete pod <name> --force --grace-period=0` and `kubectl delete rs <old-rs>` to unblock it.

### Key Learning
**Troubleshooting is peeling an onion.** Fixing the ConfigMap typo revealed the ImagePull error. The `ContainerCreating` state masked the image problem because the Pod couldn't even get to the image pull phase while the volume was failing.

---

## 3. K8 L2 — HTTPD Update & Rollback (`httpd-deploy`)

**Task:** Create namespace `nautilus`, deploy `httpd:2.4.28` with `maxSurge: 1, maxUnavailable: 2`. Upgrade to `2.4.43`, then rollback.

**The Commands:**
```bash
kubectl create namespace nautilus
# (Applied Deployment & Service manifests)
kubectl set image deployment/httpd-deploy httpd=httpd:2.4.43 -n nautilus
kubectl rollout status deployment/httpd-deploy -n nautilus
kubectl rollout undo deployment/httpd-deploy -n nautilus
```

### Key Learning
**`rollout status` must finish before `rollout undo`.** If you undo mid-rollout, it reverts to an intermediate state. Also, `maxUnavailable: 2` with 2 replicas means 0 are guaranteed available during the update—a risky production strategy meant to test the limits.

---

## 4. K8 L2 — Jenkins CI Server

**Task:** Namespace `jenkins`, Deployment `jenkins-deployment` (1 replica), Service `jenkins-service` on NodePort 30008. `JAVA_OPTS` to skip the setup wizard.

**The Fix:**
```yaml
env:
  - name: JAVA_OPTS
    value: "-Djenkins.install.runSetupWizard=false"
```
*Service mapping:* `port: 80` → `targetPort: 8080` → `nodePort: 30008`.

### Key Learning
**Jenkins is heavy.** It takes 1–2 minutes to pull the image and another 60 seconds to boot. The `JAVA_OPTS` env var must be quoted in YAML (`"-D..."`) to prevent parsing errors.

---

## 5. K8 L2 — Tomcat App

**Task:** Namespace `tomcat-namespace-devops`, Deployment `tomcat-deployment-devops`, NodePort `32227`.

**The Fix:**
Used image `kodekloud/centos-ssh-enabled:tomcat`. Service mapped `port: 80` → `targetPort: 8080`.

### Key Learning
**Image tags matter.** Using `kodekloud/centos-ssh-enabled` (without `:tomcat`) would pull the `latest` tag, which might not have the Tomcat server installed on port 8080.

---

## 6. K8 L2 — Node App

**Task:** Deployment with 2 replicas of `kodekloud/centos-ssh-enabled:node`, Service on NodePort `30012`.

**The Fix:**
Standard deployment and service manifest. Service mapped `port: 80` → `targetPort: 8080`.

### Key Learning
**The Node app takes time to initialize.** The pod will show `2/2 Running` quickly (because the SSH sidecar is up), but the Node server inside might take another 30 seconds to bind to port 8080.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 | 🟢 In Progress (Heavy progress) |
| **100 Days DevOps** | Ongoing | K8 Block |
| **Codomax Internship** | Nov 8 | Module 05 (Lambda) Completed |

---

## Key Takeaways

- 🐳 **KodeKloud App Button requires Service `port: 80`.** Always map port 80 to your app's targetPort.
- 🐳 **Troubleshooting K8s is layer-by-layer.** Fixing a volume issue can reveal an image issue underneath.
- 🐳 **`kubectl rollout status` must complete** before running `rollout undo`.
- 🐳 **Jenkins takes minutes to start.** Use `JAVA_OPTS` to skip the wizard and be patient with the pod status.
- 🐳 **The `kubectl patch --type=json` flag** is the cleanest way to fix a specific field (like a ConfigMap name) without rewriting the whole YAML.
- 🐳 **Force deleting stuck pods** (`--grace-period=0`) is sometimes necessary to unblock a broken rolling update.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Grafana | 🟢 Completed |
| K8 L2 — Redis Troubleshooting | 🟢 Completed |
| K8 L2 — HTTPD Update & Rollback | 🟢 Completed |
| K8 L2 — Jenkins Deployment | 🟢 Completed |
| K8 L2 — Tomcat Deployment | 🟢 Completed |
| K8 L2 — Node App Deployment | 🟢 Completed |

**Overall: 🟢 Day 60/100 — Completed · High-Volume K8 Sprint**

> **Realization:** Today was a marathon of Kubernetes deployments. If there's one overarching theme, it's that **Kubernetes is highly declarative, but you need to know the operational lifecycle**. Creating the resources is only half the battle. Understanding how rollouts work, how services route traffic via labels, and how to troubleshoot stuck pods (via `describe`, checking endpoints, and reading events) is the real skill. The App button 502s are a KodeKloud-specific quirk (port 80), but the Redis troubleshooting was pure, real-world K8s debugging.
