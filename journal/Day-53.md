You are completely right, and I apologize for the mix-up. Because every single task right now is Kubernetes, I blended the tracks together. 

Let me correct the record exactly as you laid it out:
*   **100 Days DevOps:** Only the `countdown-xfusion` Job.
*   **K8 L1:** The CronJob `devops`, the `webserver` sidecar troubleshooting, **and** the `nginx-deployment` rollback (which I completely left out of the previous draft!).

Here is the properly categorized and corrected journal entry for Day 53.

---

# CloudOps / DevOps Journal

## Day 53 — 4 November 2026

**Challenges:** 100 Days DevOps (K8 block) & K8 L1

> **Context:** 1 task for 100 Days DevOps, 3 tasks for K8 L1. The K8 L1 sidecar troubleshooting task remains failed due to a drained battery and a highly specific grader.

---

## 1. 100 Days DevOps — Job `countdown-xfusion`

**Task:** Job named `countdown-xfusion`, template name `countdown-xfusion`, container `container-countdown-xfusion`, image `fedora:latest`, restart policy `Never`, execute `sleep 5`.

**Corrected YAML:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: countdown-xfusion
spec:
  template:
    metadata:
      name: countdown-xfusion
    spec:
      restartPolicy: Never
      containers:
        - name: container-countdown-xfusion
          image: fedora:latest
          command: ["sleep", "5"]
```

### Key Learning
**A Job without a command will crash immediately.** The `fedora` image starts, does nothing, and exits with code 0. You must provide a command. Also, `spec.template.metadata.name` is nested deep and easy to miss when reading the prompt.

---

## 2. K8 L1 — Revert Deployment to Previous Version

**Task:** Rollback `nginx-deployment` to the previous revision.

**The Fix:**
```bash
kubectl rollout undo deployment/nginx-deployment
kubectl rollout status deployment/nginx-deployment
```

### Key Learning
**`-n` is namespace, not name.** I initially tried `kubectl rollout undo deployment -n nginx-deployment`, which told kubectl to look for a deployment in a namespace called `nginx-deployment`. The name must go in the resource reference: `deployment/nginx-deployment`.

---

## 3. K8 L1 — CronJob `devops`

**Task:** CronJob `devops`, schedule `*/2 * * * *`, container `cron-devops`, image `httpd:latest`, command `echo Welcome to xfusioncorp!`, restart policy `OnFailure`.

**YAML:**
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
**The CronJob hierarchy is deeply nested.** `CronJob` -> `jobTemplate` -> `template` -> `spec`. The `restartPolicy` goes at the Pod level inside this nesting, not the CronJob level. Using `["/bin/sh", "-c", "..."]` is required for the container to parse the echo command.

---

## 4. K8 L1 — Troubleshooting `webserver` Pod (Sidecar Failure)

**Task:** Pod `webserver`, main container `httpd-container` (`httpd:latest`), sidecar container `sidecar-container` (`ubuntu:latest`). Make the website accessible.

**The Battle:**
1. **Original issue:** The `ubuntu` sidecar started and immediately exited (no long-running process). The Pod entered `CrashLoopBackOff`.
2. **Attempt 1 (Standard Container):** Recreated the pod with `sidecar-container` in `spec.containers` with `sleep infinity`. Pod reached `2/2 Running`, `curl` returned Apache HTML. **Grader failed it.** Error: *"Website not accessible."*
3. **Attempt 2 (Native Sidecar):** Based on K8s 1.28+ docs and KodeKloud forums, moved the sidecar to `spec.initContainers` with `restartPolicy: Always`. Pod reached `2/2 Running`. **Grader failed it.** Error: *"'sidecar-container' doesn't exist."*
4. **Attempt 3:** Reverted to `spec.containers` with `tail -f /dev/null`. Pod reached `2/2 Running`. **Grader failed it.**
5. **End of day:** Laptop battery died. Task incomplete.

**Debugging notes:** Discovered that port `8080` on the KodeKloud jump-host is occupied by the web terminal (`ttyd`), so `port-forward` must use `9999`. Also discovered that `ubuntu:latest` does not have `wget` or `curl` pre-installed.

### Key Learning
**The KodeKloud grader for this task is highly specific.** The error messages are contradictory (saying the container doesn't exist in one attempt, and the website isn't accessible in another). The K8s community is split on standard vs. native sidecars for this specific lab, and the grader seems to expect a specific implementation we haven't hit yet.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ **Certified** |
| **100 Days DevOps** | Day 53 (K8 Block) | In Progress |
| **K8 L1** | 13/14 tasks done | Sidecar task remaining |
| **Terraform L2** | Paused at 5/20 | Resumes Nov 8 |
| **Projects** | 22 Nov | On track |

---

## Key Takeaways

- 🐳 **Jobs need commands.** Without a `command`, a container finishes instantly and the Job completes.
- 🐳 **`kubectl rollout undo` uses `<kind>/<name>`, not `-n <name>`.**
- 🐳 **CronJobs are nested:** `jobTemplate` > `template` > `spec`. Restart policy goes in the innermost pod spec.
- 🐳 **KodeKloud jump-host port 8080 is taken.** Use 9999 for local port-forwards.
- 🐳 **The Ubuntu image is bare.** It doesn't have `curl` or `wget`.
- 🛑 **Grader strictness:** Passing the literal task description doesn't always pass the automated grader. Sometimes it expects a very specific configuration pattern.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Job `countdown-xfusion` | 🟢 Completed |
| K8 L1 — Rollback Deployment | 🟢 Completed |
| K8 L1 — CronJob `devops` | 🟢 Completed |
| K8 L1 — Troubleshooting Sidecar | ❌ Failed (Battery died) |

**Overall: 🟡 Day 53/100 — Partial (Three tasks passed, K8 L1 sidecar task failed)**

> **Realization:** Today was a heavy Kubernetes day. Three K8 L1 tasks were cleared (Rollback, CronJob, and the 100 Days Job), leaving only the infamous `webserver` sidecar task. 
> 
> The sidecar task is a frustrating reminder that automated graders don't always read the Kubernetes docs the same way humans do. The Pod was `2/2 Running`, and the website was perfectly accessible via `curl`, but the grader still rejected it. This is a lesson in reading the task's exact wording (init vs regular containers) and knowing that sometimes, the implementation that works in real life isn't the one that passes the test. 
> 
> The battery dying was the ultimate end to a long debugging session. We'll hit it fresh tomorrow.
