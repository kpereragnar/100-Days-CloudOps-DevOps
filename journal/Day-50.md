# CloudOps / DevOps Journal

## Day 50 — 1 November 2026

**Challenges:** 100 Days DevOps, 100 Days Cloud, and K8 L1 Day 1

> **Context:** Laptop charger burned. Working entirely from phone — no `nano`, no `vi`, all files via `cat` heredocs. K8 L1 started at 2/day. Terraform L2 paused at 5/20.

---

## 1. 100 Days DevOps — Deployment `httpd`

**Task:** Deployment `httpd`, image `httpd:latest`.

```bash
kubectl create deployment httpd --image=httpd:latest
kubectl get deployment httpd -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Verified:** `httpd:latest` in the deployment spec.

### Key Learning

**`:latest` must be literal** — the grader checks the string, not the resolved default. `--image=httpd` would work but store `httpd` in the spec.

---

## 2. 100 Days Cloud — Log Aggregation Lab (FAILED — three attempts)

**Task:** Two VPCs (private + public), VPC peering, IAM role for S3, private bucket, two-instance cron chain (private scp to public, public aws s3 cp). Target path: `devops-priv-vpc/boot/boots.log`.

**Three attempts with different resource-name prefixes:** `devops-priv-vpc` → `xfusion-priv-vpc` → `devops-priv-vpc`.

### What was built successfully each time

| Layer | Status |
|---|---|
| Public VPC, subnet, IGW, route table, EC2 | ✅ |
| IAM role + policy + instance profile + associate | ✅ (after IAM/EC2 propagation delay) |
| S3 bucket | ✅ |
| VPC peering + accept + routes both directions | ✅ (peering `active`) |
| Private SG allowing port 22 from public VPC CIDR | ✅ |
| Public SG allowing port 22 from private VPC CIDR | ✅ |

### Where it failed

**SSH from aws-client to private instance via jump host (`ssh -J`) — `Connection closed by unknown port 65535`.**

The jump-host forwarding channel gets dropped by the client's OpenSSH build. `ssh -J ... "echo JUMP-OK"` sometimes worked, then failed on the next attempt. Inconsistent — appeared to be rate-limiting or a channel-closing issue.

**What we tried:**

| Attempt | Method | Result |
|---|---|---|
| 1 | `scp -J` | port 65535 |
| 2 | `cat key \| ssh -J "cat > file"` | port 65535 |
| 3 | `ssh -J ... "echo BASE64 \| base64 -d > file"` | port 65535 |
| 4 | `scp -O -J` (legacy protocol) | `unknown option -O` — older OpenSSH |
| 5 | Generate keypair on private, add pubkey to public | Failed at step 1 — connection closed |
| 6 | Check peering/routes/SG independently | All showed `active` / CIDR present |
| 7 | Ping public→private | **100% packet loss** — routing issue at the effective route table level |

**Root cause identified but not resolved before time ran out:** the private subnet's **effective route table** may not be `devops-priv-rt`. The task said "route table named devops-priv-rt exists" — but the subnet might be associated with a different RT (main, or one I didn't discover). Adding a peering route to `devops-priv-rt` doesn't help if the subnet uses a different RT.

**The diagnostic that would have found it (too late):**
```bash
PRIV_SUBNET=$(aws ec2 describe-instances --instance-ids $PRIV_EC2 \
  --query "Reservations[0].Instances[0].SubnetId" --output text)
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$PRIV_SUBNET" \
  --query "RouteTables[0].RouteTableId" --output text
# Then verify this RTB has the peering route
```

### Key Learning

**`ssh -J` is not reliable on all OpenSSH builds.** Some builds drop the forwarding channel intermittently. `echo JUMP-OK` works (output-only), but data-transfer operations (`scp`, `cat >`) fail. **If `scp -J` and stdin-piping through `-J` both fail, use AWS SSM Session Manager instead** — it bypasses SSH entirely.

**The subnet's effective route table is not necessarily the task's named route table.** The task said `devops-priv-rt` exists; it didn't say the subnet uses it. **Check `describe-route-tables --filters "Name=association.subnet-id,Values=<subnet>"` before adding routes** — the route goes on the *effective* table, not the named one.

**90% of the infrastructure was correct.** VPC, peering, IAM, S3, both EC2 instances, both SGs, both routes — all confirmed. The failure was in the last-mile command execution. **The plan absorbs this** — same as Day 47's AFIT day. K8 L1 and 100 Days don't depend on the lab.

**The honest journal records the plan-visible success and the execution failure separately.** A journal that only records wins isn't a record of the work. A journal that says "failed entirely" misrepresents what the AWS resources actually achieved. **Both are true: the infrastructure exists, the last mile didn't work.**

---

## 3. K8 L1 — Task 1: Pod `pod-nginx`

**Task:** Pod `pod-nginx`, image `nginx:latest`, label `app=nginx_app`, container `nginx-container`.

```bash
cat > /tmp/pod-nginx.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx
  labels:
    app: nginx_app
spec:
  containers:
    - name: nginx-container
      image: nginx:latest
EOF

kubectl apply -f /tmp/pod-nginx.yaml
kubectl get pod pod-nginx --show-labels
```

### Key Learning

**The label goes at `metadata.labels`, not on the container.** The container has only `name` and `image` — no label field. Same lesson as the earlier `pod-httpd` task.

**The manifest form is required** when the container name differs from the pod name — `kubectl run` defaults the container name to the pod name.

---

## 4. K8 L1 — Task 2: Deployment `nginx`

**Task:** Deployment `nginx`, image `nginx:latest`.

```bash
kubectl create deployment nginx --image=nginx:latest
kubectl get deployment nginx -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Key Learning

**Deployment → ReplicaSet → Pod is automatic.** `kubectl create deployment` produces all three. The pod is owned by the ReplicaSet, which is owned by the Deployment.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| Terraform L1 | 27 Oct | ✅ 75% |
| **Terraform L2** | Paused at **5/20** | Resumes Nov 8 |
| **K8 L1** | **2/14 done** | 2/day target, finish Nov 7 |
| **100 Days Cloud** | Day 100 → 22 Dec | On track |
| **Projects** | 22 Nov | On track |
| **Log aggregation lab** | Failed | Retry if new lab window |

---

## Key Takeaways

- 🐳 **`:latest` must be literal in the manifest** — the grader checks the string.
- 🐳 **`kubectl create deployment` is one command.** No manifest needed for simple deployments.
- 🐳 **Labels at `metadata.labels`, not on the container.** Container has only name and image.
- ☁️ **`ssh -J` fails inconsistently on some OpenSSH builds.** `echo` works, data doesn't. **Use AWS SSM Session Manager when SSH jump is unreliable** — it bypasses SSH entirely.
- ☁️ **The subnet's effective route table ≠ the task's named route table.** Always check `describe-route-tables --filters "Name=association.subnet-id,Values=<subnet>"` before adding routes.
- ☁️ **90% of a failed lab can still be real work.** VPC, peering, IAM, S3, both EC2 instances — all correctly built. The failure was last-mile command execution, not infrastructure design.
- 🔄 **The plan absorbs lab failures without moving milestones.** K8 L1 and 100 Days proceed. Terraform L2 resumes Nov 8. Projects start Nov 22.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Deployment `httpd` | 🟢 Completed |
| 100 Days Cloud — Log aggregation lab | ❌ Failed (3 attempts, SSH jump broken) |
| K8 L1 Task 1 — Pod `pod-nginx` | 🟢 Completed |
| K8 L1 Task 2 — Deployment `nginx` | 🟢 Completed |

**Overall: 🟡 Day 50/100 — Partial (lab failed, K8 L1 started)**

> **Realization:** Two things today that belong together.
>
> **The failed lab was the best diagnosis drill of the week.** The infrastructure was 90% right — VPC, peering, IAM, S3, both instances, both SGs, both routes all confirmed active. The failure was one layer down: the private subnet's **effective route table** didn't match the task's **named** route table, so the peering route I added wasn't used. And the SSH jump channel was unreliable on the phone's terminal app, which masked the routing issue for an hour. **The error message named the symptom (packet loss) but the cause lived two layers below (wrong route table) and one layer above (broken jump channel).** The diagnostic ladder that would have found it — check peering status, check effective RT routes, ping from public — was the same ladder that eventually surfaced "100% packet loss" as the pinpoint. **The lab didn't fail because the commands were wrong. It failed because the substrate underneath the commands had one wrong wire I didn't check.**
>
> **The K8 L1 pivot was the plan working.** Rather than chase a broken lab for another hour, the pivot to phone-friendly K8 tasks preserved the day's momentum. **2 K8 L1 tasks done — starting the new track.** The lab failure gets absorbed by the plan, not by the ego. Same discipline as Day 47's AFIT day: the day didn't go to plan, but the plan absorbed it without moving a milestone. **Three interruptions absorbed in five days** (AFIT, Bincom 12-hour write, phone-only day + failed lab). **The finish line is still 22 Dec.** The plan that keeps absorbing interruptions without moving the finish line is the one that survives.
