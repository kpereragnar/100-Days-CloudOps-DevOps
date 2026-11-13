---

# CloudOps / DevOps Journal

## Day 62 — 13 November 2026

**Challenges:** 100 Days DevOps & K8 L2 (Final Tasks)

> **Context:** Finished the K8 L2 track. The first task was the daily 100 Days DevOps curriculum (Init Containers), and the second was the final K8 L2 task (LAMP-WP Troubleshooting).

---

## 1. 100 Days DevOps — Init Containers (`ic-deploy-nautilus`)

**Task:** Create a Deployment `ic-deploy-nautilus` with an `emptyDir` volume. The init container (`ic-msg-nautilus`) writes a file to `/ic/ecommerce`, and the main container (`ic-main-nautilus`) reads it in a loop.

**The Fix:**
Used the `emptyDir` volume to bridge the two containers. 
```yaml
      initContainers:
        - name: ic-msg-nautilus
          image: debian:latest
          command: ["/bin/bash", "-c", "echo Init Done - Welcome to xFusionCorp Industries > /ic/ecommerce"]
          volumeMounts:
            - name: ic-volume-nautilus
              mountPath: /ic
      containers:
        - name: ic-main-nautilus
          image: debian:latest
          command: ["/bin/bash", "-c", "while true; do cat /ic/ecommerce; sleep 5; done"]
          volumeMounts:
            - name: ic-volume-nautilus
              mountPath: /ic
```

### Key Learning
**Applying the K8 L1 lesson:** For Q1 of the K8 L1 assessment, I failed because I split `command` and `args`. This time, I put the entire `/bin/bash -c "..."` string inside the `command` array. It worked perfectly on the first try.

**Init containers run exactly once.** The init container writes the file and exits. Then the main container starts and reads it. `kubectl logs` shows the main container successfully printing the greeting every 5 seconds.

---

## 2. K8 L2 — LAMP Stack Troubleshooting (`lamp-wp`)

**Task:** The LAMP-WP WordPress site went down. Fix it without deleting or modifying existing deployment names, service names, or secrets. 

**The Investigation:**
The pod was `2/2 Running`. The database was up. The env vars (`MYSQL_HOST`, `MYSQL_USER`, etc.) were perfectly set on both containers. But curling the site returned: `Unable to Connect to ''`.

**The 3 Bugs Found:**
1.  **NodePort Mismatch:** The `lamp-service` was on NodePort `30009`, but the task required `30008`.
    *   *Fix:* `kubectl patch svc lamp-service -p '{"spec":{"ports":[{"port":80,"targetPort":80,"nodePort":30008}]}}'`
2.  **PHP Code Typos (The main issue):** I read `/app/index.php` inside the container. The junior dev who wrote it had two typos:
    *   `$dbpass = $_ENV['MYSQL_PASSWORDS'];` (extra 'S' at the end).
    *   `$dbhost = $_ENV['HOST_MYQSL'];` (Y and Q swapped).
    *   Because `HOST_MYQSL` didn't exist, PHP passed an empty string to `mysqli_connect()`, causing the `Unable to Connect to ''` error.
    *   *Fix:* Used `sed` inside the running container to fix the typos in the live file:
        ```bash
        kubectl exec $POD -c httpd-php-container -- sed -i "s/HOST_MYQSL/MYSQL_HOST/g" /app/index.php
        kubectl exec $POD -c httpd-php-container -- sed -i "s/MYSQL_PASSWORDS/MYSQL_PASSWORD/g" /app/index.php
        ```

**Verification:**
```bash
curl -s http://localhost:30008
# → "Connected successfully"
```

### Key Learning
**"Running" does not mean "Working."** Both containers were green in `kubectl get pods`, but the application was completely broken. You have to test the actual HTTP endpoint. 

**Read the source code.** If the environment variables are perfect and the network is fine, the bug is in the application logic. Using `kubectl exec` to `cat` the PHP file revealed the typos instantly. 

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 14 | ✅ **Completed** |
| **100 Days DevOps** | Ongoing | K8 Block |
| **Terraform L2** | Paused at 5/20 | Resumes next |
| **Codomax Internship** | Nov 8 | Module 05 (Lambda) Completed |

---

## Key Takeaways
- 🐳 **`command: ["/bin/bash", "-c", "..."]`** as a single array is the safest way to pass shell scripts in K8s YAML.
- 🐳 **Init containers are perfect for bootstrapping files** into a shared `emptyDir` before the main app starts.
- ☁️ **LAMP troubleshooting requires checking all 3 layers:** the K8s Service ports, the container Env Vars, and the application code itself.
- ☁️ **`sed -i` inside a running container** is a fast way to hotfix code if you can't rebuild the image.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Init Container | 🟢 Completed |
| K8 L2 — LAMP Troubleshooting | 🟢 Completed |

**Overall: 🟢 Day 62/100 — Completed · K8 L2 Track Finished**

> **Realization:** The LAMP troubleshooting task was the perfect capstone for the K8 L2 track. It required everything we've learned: patching Services, reading container environment variables, diagnosing network routing, and ultimately reading the application source code. The error `Unable to Connect to ''` was a brilliant trap—it looked like a Kubernetes networking issue, but it was a simple typo in a PHP script. You have to debug layer by layer until you find the exact broken link.
