Here is the clean, verified journal entry for **Day 51**. 

I’ve gone back through the logs from that day to make sure the failures (the YAML tab error, the `-n` namespace flag mistake, and the log aggregation lab failure) are documented accurately and match the format we just used for Day 52.

---

# CloudOps / DevOps Journal

## Day 51 — 2 November 2026

**Challenges:** 100 Days DevOps, K8 L1

> **Context:** Four K8 L1 tasks completed. The log aggregation lab failed again (3rd distinct attempt).

---

## 1. K8 L1 — Setup Namespaces and PODs

**Task:** Namespace `dev`, pod `dev-nginx-pod`, image `nginx:latest`.

**First attempt failed** — `nano` YAML had bad indentation: 
`error: error parsing /tmp/nginx-pod.yaml: error converting YAML to JSON: yaml: line 2: mapping values are not allowed in this context`

**Fixed with heredoc:**
```bash
kubectl create namespace dev
cat > /tmp/nginx-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: dev-nginx-pod
  namespace: dev
spec:
  containers:
    - name: nginx
      image: nginx:latest
EOF
kubectl apply -f /tmp/nginx-pod.yaml
```

### Key Learning
**`line 2: mapping values are not allowed` is almost always a tab character.** Nano inserts tabs on the Tab key — YAML requires spaces. **The heredoc form is immune** because it writes content literally with no editor interpretation. Use `cat << 'EOF'` for every manifest.

**The namespace goes in `metadata.namespace`, not in the filename or `-f` flag.** `kubectl get pod dev-nginx-pod` (without `-n dev`) returns `NotFound` — always verify with `-n`.

---

## 2. K8 L1 — Set Resource Limits on `httpd-pod`

**Task:** Pod `httpd-pod`, container `httpd-container`, image `httpd:latest`. Requests 15Mi/100m, limits 20Mi/100m.

```bash
cat > /tmp/httpd-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: httpd-pod
spec:
  containers:
    - name: httpd-container
      image: httpd:latest
      resources:
        requests:
          memory: "15Mi"
          cpu: "100m"
        limits:
          memory: "20Mi"
          cpu: "100m"
EOF
kubectl apply -f /tmp/httpd-pod.yaml
```

### Key Learning
**20Mi memory is extremely tight for `httpd:latest`.** Apache typically needs 50–100Mi minimum. The pod may OOMKill on startup — **that's still a pass** if the grader checks the spec. The task explicitly asked for 20Mi; the values are the contract.

---

## 3. K8 L1 — Execute Rolling Updates to `nginx:1.18`

**Task:** Deployment `nginx-deployment`, update image to `nginx:1.18`.

```bash
# Get container name (needed for `set image`)
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].name}{"\n"}'

# Update — container name on left, new image on right
kubectl set image deployment/nginx-deployment nginx=nginx:1.18

# Watch
kubectl rollout status deployment/nginx-deployment
```

### Key Learning
**`kubectl set image` needs the container name, not just the new image.** `deployment/nginx-deployment nginx=nginx:1.18` — the left of `=` is the container name, the right is the new image. If you forget the container name, use `*=` to match all containers.

---

## 4. K8 L1 — Revert Deployment to Previous Version

**Task:** Rollback `nginx-deployment` to the previous revision.

**First attempt failed:**
```bash
kubectl rollout undo deployment -n nginx-deployment
# ❌ tries to find deployment in namespace "nginx-deployment" — which doesn't exist
```

**The fix:**
```bash
kubectl rollout undo deployment/nginx-deployment
kubectl rollout status deployment/nginx-deployment
```

### Key Learning
**`-n` is namespace, not name.** The name goes in the resource reference: `<kind>/<name>`. This is the same across `get`, `delete`, `describe`, `rollout undo`, `set image` — **every `kubectl` command that acts on a specific resource uses the slash form, not a flag.**

---

## 5. 100 Days Cloud — Log Aggregation Lab (Failed Again)

**Third attempt with xfusion prefixes. Failed again.** 

**First attempt** (datacenter): SSH jump channel dropped (`port 65535`), never got to cron setup.
**Second attempt** (datacenter): Grader rejected S3 content because I had appended `entry-XXX` lines to `/var/log/boots.log` via `sudo tee -a`.
**Third attempt** (xfusion): Fresh runbook, did not append to `boots.log`. Completed execution, but did not confirm final S3 state before the lab window closed.

### Key Learning
**`tee -a` appends.** The file had pre-existing content from the lab's setup. Adding lines changed the file from what the grader expected to what the grader rejected. **`sudo cat /var/log/boots.log` before writing — 2 seconds, saves the submission.**

---

## 6. K8 Sheet Critique — Adding a Task Index

Realized the K8 sheet lacked a "how do I do X" index. The rolling update commands existed in §2.6, §4.2, and Playbook 3, but the connection between the task verb and the section wasn't front-loaded. 

**The fix:** Add a 15-line task index at the top mapping tasks to sections. 

---

## Timeline

| Track | Date | Status |
|---|---|---|
| **K8 L1** | 6/14 tasks | 2/day pace, finish ~Nov 6–7 |
| **Terraform L2** | Paused at 5/20 | Resumes Nov 8 |
| **100 Days Cloud** | Day 100 → 22 Dec | On track |
| **Projects** | 22 Nov | On track |

---

## Key Takeaways
- 🐳 **YAML `line 2: mapping values not allowed` = tab character.** Heredoc is the fix.
- 🐳 **Namespace goes in `metadata.namespace`** — not in the filename or `-f` flag.
- 🐳 **`kubectl set image` needs the container name.** `deployment/<n> <container>=<new-image>`.
- 🐳 **`-n` is namespace, not name.** Resource names go in `<kind>/<name>` references.
- ☁️ **`tee -a` appends.** `cat` the file before writing to know what you're adding to.

---

## Day Status
| Area | Status |
|---|---|
| K8 L1 — Namespace + Pod | 🟢 Completed |
| K8 L1 — Set Resource Limits | 🟢 Completed |
| K8 L1 — Rolling Update | 🟢 Completed |
| K8 L1 — Revert to Previous | 🟢 Completed |
| 100 Days Cloud — Log Aggregation | ❌ Failed (attempt 3, unconfirmed) |

**Overall: 🟡 Day 51/100 — Partial (lab failed, 4 K8 tasks passed)**

> **Realization:** The errors today were all shape mismatches the journal has documented before: the tab character, the namespace flag, the missing container name. Same class, four new surfaces. The pattern holds across every tool: **the tool's syntax is narrower than the assumption of it, and the error names the exact gap.**
>
> The log aggregation lab — third failure, third reason. The first was infrastructure (jump channel). The second was content (`tee -a` added lines the grader didn't expect). The third attempt encoded both fixes, but I don't have confirmation if it passed. **The lab is a detour, not a derailment.** K8 L1 is moving forward.
