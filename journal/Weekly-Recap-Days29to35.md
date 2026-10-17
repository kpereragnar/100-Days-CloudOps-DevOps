# 📊 Weekly Recap — Days 29–35

[![Week](https://img.shields.io/badge/week-5-blue)](#)
[![Days](https://img.shields.io/badge/days-29--35-green)](#)
[![Status](https://img.shields.io/badge/status-completed-brightgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 5: Days 29–35

> **Week 5 moved from individual resources into full workflows — gated merges, cross-VPC connectivity, automated routing, and end-to-end web application deployment.**

Covered: **Git (PRs, reset, stash, rebase, hooks), AWS VPC Peering, NAT Instances, RDS, Lambda, IAM, DynamoDB, Kinesis, SNS, CloudWatch Logs, Docker Compose, and Terraform (20+ services added to the reference).**

> 🔑 **Theme of the week:** read the task literally, verify the result after every command, and understand the chain of dependencies before troubleshooting.

---

## 📅 Daily Summary

| Day | DevOps | AWS | Personal |
|---|---|---|---|
| **29** | Git Pull Request workflow | VPC Peering (routes both sides, ICMP, SG) | 🏆 **Jenkins L1 — 100%** |
| **30** | Git reset (`--hard` + force push) | NAT Instance (4 retries — wrong route table) | Terraform basics (VPC, SG, key pair) |
| **31** | Git stash (`stash@{1}`) | Private RDS (gp2, version pinning) | Terraform L1 (EIP, key pair, EC2, AMI) |
| **32** | Git rebase (no merge commit) | RDS snapshot + restore | EBS, snapshot, CloudWatch alarm |
| **33** | Rebase conflict (heredoc fix) | Lambda + IAM role (v1 CLI payload issue) | IAM group + policy |
| **34** | Post-update hook (auto-tag) | Lambda CLI deploy | DynamoDB, Kinesis, SNS |
| **35** | Docker + Compose install | RDS retry (8.4 → 8.4.5), EC2, PHP | SSM parameter, CloudWatch logs |

---

## 🎯 Three Big Themes

### 1. Git stopped being "commands" — became "workflows"

Every task was a **scenario** (a reviewer, a cleanup, a conflict), not syntax. The pattern: PRs are gated merges, `--hard` cleans history, `apply` vs `pop` matters, rebase replays without merge commits, server-side hooks live in the bare repo.

### 2. Terraform shifted from "learning" to "referencing"

The sheet grew from ~40 to **60+ services** this week. Every task either **reinforced** or **revealed** a gap. CloudWatch log streams, Kinesis, SNS, DynamoDB arguments — all added when tasks exposed them.

### 3. AWS failures were always missing links, never wrong syntax

| Task | Root cause | Fix |
|---|---|---|
| NAT Instance | Route in wrong table (main, not custom) | Query `association.subnet-id` |
| VPC Peering | SG missing SSH rule | Add port 22 |
| RDS (Day 35) | `--engine-version 8.4` resolved to latest patch | Pin `8.4.5` + `--no-auto-minor-version-upgrade` |

---

## 🔥 Hardest Moments

**NAT Instance (Day 30) — 4 retries.** iptables on wrong interface (`eth0` vs `enX0`), FORWARD chain showed 0 packets, NACLs fine — the actual issue was the route in the **wrong route table**. The fix was one line.

**Rebase Conflict (Day 33).** No `nano` or `vim` on the server. Used a heredoc to rewrite `story-index.txt`, then `git add` → `git rebase --continue` → `git push`.

**RDS Retry (Day 35).** First submission failed: "not using MySQL 8.4.5." Root cause was `--engine-version 8.4` resolving to the latest patch. Fixed with exact version pinning + auto-upgrade disabled. Also hit the private-IP SSH trap (`172.31.x.x` unreachable from outside VPC) and the no-key-pair bootstrap problem (used EC2 Instance Connect).

---

## 🧠 Skills Sharpened

| Area | Growth |
|---|---|
| **Git** | PRs, reset, stash, rebase, conflicts, server-side hooks |
| **AWS Networking** | VPC peering, NAT instance, route table associations, SG chaining |
| **AWS Database** | RDS create, snapshot, restore, version pinning |
| **AWS Serverless** | Lambda + IAM role + CLI deploy |
| **AWS Messaging** | DynamoDB, Kinesis, SNS |
| **AWS Logging** | CloudWatch log groups + streams |
| **SSH** | Key generation, passwordless auth, bootstrap without key pair |
| **Terraform** | 60+ services, CLI translation, exceptions list (~50 flags) |
| **Docker** | CentOS install, plugin architecture |

---

## 🏅 Certifications

| Badge | Status |
|---|---|
| 🐧 Jenkins L1 | **100%** ✅ (earned Day 29) |
| ⚙️ Ansible L1 | 100% ✅ |
| 🌿 Git L1 | 100% ✅ |
| 🐧 Linux L1 | 86% ✅ |
| 🐳 Docker L1 | 80% ✅ |

---

## 🎓 Five Lessons That Stuck

1. **Read the task literally — build only what it asks.** CloudWatch alarm failed 3 times because I kept adding an EC2 instance the task never required.
2. **Verify after every create — `describe`, `show`, `status`.** The API returning success doesn't mean the result is correct. 10 seconds of checking saves an hour.
3. **Silent failures mean missing links, not wrong syntax.** Network → routing → firewall → auth. Never jump to step 4 when step 1 is broken.
4. **Cheat sheets grow through gaps, not planning.** CloudWatch log streams were missing until Day 35 exposed them. Use the sheet, find the hole, patch it.
5. **The tool doesn't adapt to you.** `docker-compose` is dead, `<URL>` isn't a command, `ssh -i` needs `authorized_keys`, `8.4` isn't `8.4.5`, `172.31.x.x` isn't reachable. Read the error, adapt.

---

## 📊 Week in Numbers

| Metric | Count |
|---|---|
| Days completed | 7 |
| Git tasks | 6 |
| AWS tasks | 6 |
| Terraform tasks | 18 |
| Certifications earned | 1 (Jenkins L1) |
| Failed attempts before success | 6 |
| Terraform services added | 20+ |
| Debugging sessions over 1 hour | 2 |

---

## 🎯 Focus for Week 6

* ☁️ More AWS services (ECS, EKS, Route 53, advanced networking)
* ⚙️ Terraform deepening — modules, state, workspaces
* 🐳 Docker + ECR pipeline work
* 🔄 CI/CD and repeatable container deployment
* 🔐 AWS IAM, networking, monitoring, cloud security

---

## 💡 Week 5 Major Realization

> **Success of the API call does not mean correctness of the result.**
>
> The RDS task failed because I never verified the output — `--engine-version 8.4` created an instance, the command returned successfully, and I assumed it was correct. The NAT instance failed four times for the same reason — I assumed the route was in the right table because I ran the command.
>
> The pattern is consistent across Git, AWS, and Terraform: **the tool doesn't tell you when it's wrong.** It returns success and lets you find out later. The only defense is verification — a 2-second `describe` or `show` after every create.
>
> Every tool has a "describe" or "show" command for exactly this reason. Use them.

---

<div align="center">

## ✅ Overall: 🟢 Week 5 — Days 29–35 Completed

**35/100 Days Complete**

</div>
