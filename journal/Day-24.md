```markdown
# CloudOps / DevOps Journal

## Day 24 — 6 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Git Branching

I was tasked with working through Git branching operations.

### What I Did

Since I had already covered branching extensively during Git L1 and L2, the task felt routine. The workflow I used:

```bash
# Create and switch to a new branch
git checkout -b feature-branch

# Make changes, stage, commit
git add .
git commit -m "feat: add new feature"

# Switch back to main
git checkout main

# Merge the branch
git merge feature-branch

# Delete the branch
git branch -d feature-branch
```

### Key Learning

> **Consistency beats memorization.**

Branching commands that required research a few weeks ago are now second nature. The Git L1 and L2 practice meant this task took a couple of minutes rather than a full session.

The reinforcement: **branching is the core of Git collaboration.** Whether it's a feature branch, hotfix, or release branch, the workflow is the same — create, work, merge, delete.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Set Up an Application Load Balancer

I was tasked with setting up a complete ALB stack:

1. Create an Application Load Balancer named `datacenter-alb`
2. Create a target group named `datacenter-tg`
3. Create a security group named `datacenter-sg` to open port 80 for the public
4. Attach the security group to the ALB
5. Route traffic on port 80 to port 80 of the `datacenter-ec2` instance
6. Modify the EC2's default security group if needed

### What I Did

**Step 1 — Gathered resource IDs (VPC, subnets, EC2 instance):**

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=datacenter-ec2" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

VPC_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].VpcId" --output text)

SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[].SubnetId" --output text)
```

**Step 2 — Created the security group `datacenter-sg`:**

```bash
ALB_SG=$(aws ec2 create-security-group \
  --group-name datacenter-sg \
  --description "Allow HTTP from public for ALB" \
  --vpc-id "$VPC_ID" \
  --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$ALB_SG" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

**Step 3 — Created the target group `datacenter-tg`:**

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name datacenter-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id "$VPC_ID" \
  --query "TargetGroups[0].TargetGroupArn" --output text)
```

**Step 4 — Created the ALB `datacenter-alb`:**

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name datacenter-alb \
  --type application \
  --scheme internet-facing \
  --subnets $SUBNETS \
  --security-groups "$ALB_SG" \
  --query "LoadBalancers[0].LoadBalancerArn" --output text)

aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"
```

**Step 5 — Registered the EC2 with the target group:**

```bash
aws elbv2 register-targets \
  --target-group-arn "$TG_ARN" \
  --targets Id="$INSTANCE_ID",Port=80
```

**Step 6 — Created the listener (this was the missing piece):**

```bash
aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"
```

**Step 7 — Allowed the ALB to reach the EC2:**

```bash
EC2_SG=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$EC2_SG" \
  --protocol tcp --port 80 \
  --source-group "$ALB_SG"
```

### Issues I Faced and How I Fixed Them

**Issue — ALB existed but traffic didn't flow (503 error)**

I had created the ALB, target group, and security group — but `curl http://<alb-dns>` returned `503 Service Unavailable`.

**What I checked:**

- Target health: `unhealthy`
- Listener on the ALB: **missing**
- EC2 security group: didn't allow the ALB's SG

**The root cause:** I had created all the resources but hadn't connected them. Three things were missing:

1. **The listener** — what bridges the ALB to the target group on port 80
2. **The target registration** — without it, the TG had no backends
3. **The EC2's SG rule** — without it, the ALB's traffic was dropped by the EC2

**The fix:** added all three. After that, `curl http://<alb-dns>` returned `200 OK`.

### Key Learning

> **A task that says "route traffic" is really three tasks: create the path, connect the pieces, allow the flow.**

The dependency chain matters:

```text
Client → ALB (needs SG)
              ↓
         Listener (needs ALB + TG)
              ↓
         Target Group (needs EC2 registered)
              ↓
         EC2 SG (needs to allow ALB's SG)
              ↓
         Port 80 on EC2
```

Miss any link and the chain breaks. Errors like `503` and `timeout` tell you **which link** failed:

- `503` → target unhealthy → check registration + EC2 SG
- `timeout` → ALB's own SG doesn't allow port 80
- `404` → routing works, app has no content

The methodology I used once I stopped guessing:

```text
1. READ    → What resources? What depends on what?
2. MAP     → Draw the dependency graph
3. ORDER   → Build foundation first
4. BUILD   → One piece at a time, verify each
5. TEST    → End-to-end. Walk the chain backwards when broken.
```

This isn't memorization — it's **dependency thinking.** It's the actual DevOps skill.

---

## 3. Personal Task — Ansible L1 Certification

### Completed Ansible L1 Assessment

I completed the **KodeKloud Engineer Ansible L1 Certification Assessment** with a score of **100%** (passing: 80%).

### What the Assessment Covered

**10 practical tasks, 120 minutes.** No multiple-choice. Live servers, live terminal.

Topics included:

- Creating INI inventories with host variables
- Copying files across multiple servers with the `copy` module
- Setting per-host file ownership using `{{ ansible_user }}`
- Creating files and directories with specific permissions and states
- Configuring Ansible defaults (`host_key_checking`, `become_ask_pass`, `remote_user`)
- Using `localhost` and inline `content:` with the `copy` module
- Installing packages on specific hosts only (not all)
- Troubleshooting YAML and inventory parsing errors

### Issues I Faced and How I Fixed Them

**Issue 1 — YAML indentation errors**

```
did not find expected '-' indicator
```

**Root cause:** Sibling list items must be at the **same column**. When two `- name:` lines were misaligned, YAML couldn't tell if the second was a sibling or nested content, so it failed.

**Fix:** 2-space indentation consistently. `ansible-lint` and `yamllint` catch this.

**Issue 2 — Inventory variable typo**

```ini
stapp01 ansible_user-tony ansible_ssh_pass=Ir0nM@n
                ^^^^ hyphen, should be =
```

**Root cause:** Ansible silently ignores variables it doesn't recognize. `ansible_user-tony` isn't a variable — it's an unrecognized token. No warning — just `Permission denied (publickey)` much later.

**Fix:** `ansible_user=tony` (underscore, `=`). **Inventory variables use underscores, not hyphens.**

**Issue 3 — `file` module has no `touch:` parameter**

I tried:

```yaml
file:
  touch: /opt/data.txt
```

**Error:** `Unsupported parameters for (file) module: touch`

**Fix:** Use `path:` + `state: touch`:

```yaml
file:
  path: /opt/data.txt
  state: touch
```

**Issue 4 — `-i localhost` failed to parse**

```
Unable to parse /home/thor/ansible/localhost as an inventory source
```

**Root cause:** `-i localhost` treats `localhost` as a **file path**, not a hostname. Ansible fell back to implicit localhost, and `hosts: all` didn't match it.

**Fix:** Use `hosts: localhost` in the playbook so it matches the implicit localhost.

**Issue 5 — Per-host ownership on 3 different servers**

The task required `tony` on stapp01, `steve` on stapp02, `banner` on stapp03 to own the same file.

**Solution:** Use `{{ ansible_user }}` — the inventory's per-host variable:

```yaml
file:
  path: /opt/nfsshare.txt
  state: touch
  mode: '0744'
  owner: "{{ ansible_user }}"
  group: "{{ ansible_user }}"
```

One playbook, three different owners — because the variable resolves per-host from the inventory.

### Key Learning

> **Ansible is: Inventory → Playbook → Task → Module → State.**

The syntax is easy once you internalize the pattern. What matters is:

- **Idempotency** — running the playbook 100 times produces the same result as once
- **Per-host variables** — one playbook, different behavior per host, driven by data
- **Module parameters** — every module has its own vocabulary; look them up with `ansible-doc -s <module>`
- **Task alignment** — YAML is whitespace-sensitive; sibling tasks must align

**You don't memorize playbooks.** You memorize the 6-line skeleton and the top 10 modules, and you look up the rest.

---

## Key Takeaways

- 🌿 **Git branching is muscle memory now.** L1 and L2 practice made it trivial.
- ⚖️ **ALB setup is 4 linked resources.** ALB + Listener + Target Group + EC2 SG rule. Missing one breaks the chain.
- 🧭 **Error messages point at layers, not commands.** `503` means target health. `timeout` means the ALB's SG. `404` means the app has no content.
- 🔍 **`ansible-doc -s <module>` is your best friend.** Nobody memorizes module parameters.
- 📐 **YAML indentation is syntax.** Misaligned siblings break parsing — always 2 spaces, always aligned.
- 🔤 **Inventory variables use underscores.** `ansible_user`, not `ansible-user`.
- 🎭 **Per-host differences come from variables.** One playbook can produce different outcomes by resolving `{{ ansible_user }}` from the inventory.
- 🧠 **Dependency thinking is the real skill.** Not the commands — the ability to see what depends on what, build in order, and walk the chain backwards when something breaks.

---

## Day Status

| Area                       | Status        |
| -------------------------- | ------------- |
| 100 Days DevOps            | 🟢 Completed  |
| 100 Days Cloud — AWS       | 🟢 Completed  |
| Personal Ansible L1        | 🟢 100% ✅     |
| Git (branching)            | 🟢 Reinforced |
| AWS (ALB)                  | 🟢 Completed  |
| Ansible (L1 certified)     | 🟢 Complete   |

**Overall: 🟢 Day 24/100 — Completed**

> **Major realization:** Today was the day the dependency graph became second nature. The ALB task taught me that "route traffic" is really four connected resources — miss one and the whole chain breaks. The Ansible assessment showed me that per-host differences don't need per-host code — just per-host variables. Both lessons are the same underlying principle: **understand what depends on what, and let the data drive the behavior.**
```

