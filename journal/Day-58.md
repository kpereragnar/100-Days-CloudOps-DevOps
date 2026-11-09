# CloudOps / DevOps Journal

## Day 58 — 9 November 2026

**Challenges:** 100 Days DevOps & K8 L2

> **Context:** Today's daily task was a duplicate. The 100 Days DevOps prompt and the K8 L2 task were exactly the same (`print-envars-greeting`). Knocked it out in one go.

---

## 1. 100 Days DevOps & K8 L2 — Environment Variables Pod (`print-envars-greeting`)

**Task:** Create a pod `print-envars-greeting` with container `print-env-container` using the `bash` image. Set three env vars (`GREETING`, `COMPANY`, `GROUP`), run a specific echo command, and set `restartPolicy: Never`.

**The Manifest:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-envars-greeting
spec:
  restartPolicy: Never
  containers:
    - name: print-env-container
      image: bash:latest
      env:
        - name: GREETING
          value: "Welcome to"
        - name: COMPANY
          value: "DevOps"
        - name: GROUP
          value: "Group"
      command: ["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']
```

**Verification:**
```bash
kubectl apply -f /tmp/print-envars.yaml
kubectl logs -f print-envars-greeting
```

**Output:**
```text
Welcome to DevOps Group
```

### Key Learning

**`restartPolicy: Never` is critical here.** Because the `echo` command executes and finishes in milliseconds, Kubernetes would normally restart the container indefinitely (creating a `CrashLoopBackOff` loop). Setting the policy to `Never` allows the container to exit cleanly. If you run `kubectl get pods`, you will see the status as `Completed`, not `Running`. This is the expected behavior for a one-off execution.

**Environment variable expansion requires a shell.** The command is wrapped in `/bin/sh -c`. Without the `-c` and the shell, Kubernetes would try to execute the literal string `$(GREETING)` as a binary and fail. The shell is what resolves the `$VARIABLE` syntax into the actual values.

**Expect duplicate tasks.** As the tracks converge on Kubernetes fundamentals, the 100 Days curriculum and the KodeKloud Engineer K8 L2 track will occasionally overlap. This is a bonus—one task clears two checkboxes for the day.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 | 🟢 In Progress (4 tasks done) |
| **Codomax Internship** | Nov 8 | Module 05 (Lambda) Completed |
| **Terraform L2** | Paused at 5/20 | Resumes after K8 L2 or alternates |

---

## Key Takeaways
- 🐳 **`restartPolicy: Never`** allows a pod to exit cleanly into the `Completed` state without triggering a crash loop.
- 🐳 **Shell expansion** (`$(VAR)`) requires wrapping the command in `/bin/sh -c`.
- 🎯 **Double-dipping:** One task counted for both the 100 Days DevOps and K8 L2 tracks.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Env Vars Pod | 🟢 Completed |
| K8 L2 — Env Vars Pod | 🟢 Completed (duplicate) |

**Overall: 🟢 Day 58/100 — Completed**

> **Realization:** A quick, clean day. The biggest lesson wasn't the YAML itself, but understanding *why* `restartPolicy: Never` exists. A container that runs a script and exits successfully doesn't need to be restarted; in fact, restarting it causes a fake "crash loop." The `Completed` status is a signal of success for a job-like pod, not a failure. 
>
> K8 L2 is getting into environment variables and configuration injection. This is where apps start becoming dynamic. Tomorrow, we keep moving.
