```markdown
# 📊 Weekly Recap — Days 15–21

[![Week](https://img.shields.io/badge/week-3-blue)](#)
[![Days](https://img.shields.io/badge/days-15--21-green)](#)
[![Status](https://img.shields.io/badge/status-completed-brightgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 3: Days 15–21

> **Week 3 moved from basic Linux and AWS administration into interconnected CloudOps / DevOps infrastructure.**

Covered: **Apache**, **Nginx**, **PHP-FPM**, **PostgreSQL**, **MariaDB**, **Git**, **AWS IAM**, **Elastic IPs**, **Docker**, and **load balancing**.

> 🔑 **Theme of the week:** configuring infrastructure is rarely just running the right command — it's understanding how services communicate, how resources depend on each other, and how to troubleshoot when something breaks.

---

## 📅 Day 15 — Journal Entry

> ⚠️ **Details not included in the material provided.** Left open rather than invented.

---

## 📅 Day 16 — Nginx Load Balancing, IAM User & Docker L1

### 🛠️ DevOps
Configured the **Nginx Load Balancer** for Nautilus:
- Installed Nginx, configured HTTP load balancing across all app servers
- Modified only `/etc/nginx/nginx.conf`
- Kept Apache ports unchanged
- Tested with `curl http://stlb01:80`

```text
        Client
           ↓
   Nginx Load Balancer
           ↓
 ┌─────────┬─────────┬─────────┐
App 1    App 2    App 3
Apache   Apache   Apache
```

### ☁️ AWS
Created an **IAM user** via CLI — first time doing it outside the console.

```bash
aws iam create-user --user-name <username>
```

### 🐳 Docker
Completed 2 Docker L1 tasks + **Docker L1 Assessment**.

> ## 🏆 **80% — ✅ PASS** (passing: 60%)

---

## 📅 Day 17 — PostgreSQL, IAM Group & Docker L2

### 🛠️ DevOps
Installed and configured **PostgreSQL** — created user, password, database, granted access via `psql`.

> 💡 Built directly on my Linux service-management skills.

### ☁️ AWS
Created an **IAM group** via CLI.

### 🐳 Docker L2
Completed **Docker Update Permissions** and **Create a Docker Image From Container**.

---

## 📅 Day 18 — MariaDB, IAM Policy & Docker L2

### 🛠️ DevOps
Installed and configured **MariaDB** — same pattern as PostgreSQL: user, password, database, grants.

> 💡 Working with **two database systems** built practical cross-DB exposure.

### ☁️ AWS
Created an **IAM policy for EC2** — introduced me to **JSON policy documents**.

> 💡 First step beyond just creating users/groups — understanding how permissions themselves are structured.

### 🐳 Docker L2
Completed **Docker EXEC** and **Write a Dockerfile**.

> ## 🏁 **Milestone: Structured Docker learning complete.**

Next phase: apply it to real projects. First target: **Hybrid Scanner** (my cybersecurity tool).

---

## 📅 Day 19 — Apache, IAM Policy Attachment & Docker

### 🛠️ DevOps
Deployed two websites on **stapp01** via Apache:
- Port **6400**, server name `stapp01`, root `/var/www/html`
- Copied `/beta` and `/demo` from jump host, set ownership/permissions
- Validated with `httpd -t` → **Syntax OK**
- Tested both sites via `curl http://stapp01:6400/demo/` and `/beta/`

> ## 💡 **Validate before restarting.**
> `httpd -t` catches config errors before they affect the running service.

> **Permissions matter:** a valid config still fails if ownership/permissions are wrong.

### ☁️ AWS
Attached a policy to an IAM user.

> 💡 **Key lesson:** attach commands take the **policy ARN**, not the policy ID.

**Still to learn:** managed vs inline policies, policy document structure, trust policies, policy versioning.

### 🐳 Docker
Continued hands-on practice.

---

## 📅 Day 20 — Nginx + PHP-FPM, IAM Role & Hybrid Scanner Dockerfile

### 🛠️ DevOps
Configured **Nginx + PHP-FPM** on stapp02:
- Nginx on port **8095**, root `/var/www/html`
- PHP-FPM **8.1** using socket `/var/run/php-fpm/default.sock`
- Tested with `curl http://stapp02:8095/index.php`
- Left existing `index.php` and `info.php` untouched

```text
   Client → Nginx :8095 → PHP-FPM → PHP App
```

> ## 💡 **Installing a service is only the beginning. The real work is configuring services to communicate correctly.**

### ☁️ AWS
Created an **EC2 service role**:

| Field | Value |
|---|---|
| Role Name | `iamrole_rose` |
| Entity Type | AWS Service |
| Use Case | EC2 |
| Policy | `iampolicy_rose` |

### 🐳 Docker
Created a **Dockerfile for Hybrid Scanner** — first time applying Docker to my own project.

---

## 📅 Day 21 — Bare Git Repo, Elastic IP & Power Outage

### 🛠️ DevOps
Created a **bare Git repository**:

```bash
git init --bare /opt/official.git
git rev-parse --is-bare-repository   # → true
```

| | Bare | Non-Bare |
|---|:---:|:---:|
| Working tree | ❌ | ✅ |
| `.git/` subdir | ❌ | ✅ |
| Purpose | Server-side remote | Developer workspace |

> 💡 `.git` suffix = naming convention. `--bare` = what makes it bare.

### ☁️ AWS
Created and associated an **Elastic IP** with an EC2 instance.

```text
Create Key Pair → Launch EC2 → Allocate EIP → Associate EIP
```

> 💡 EIPs are **associated**, not "attached." Lifecycle: allocate → associate → release.

### 🌩️ Personal
Missed due to **power outage**.

> ## **One missed day is not a reason to stop the journey. Continue.**

---

# 🧠 Skills Developed

| Area | Highlights |
|---|---|
| 🐧 **Linux** | Apache, Nginx, PHP-FPM, Unix sockets, PostgreSQL, MariaDB, permissions, service validation |
| ☁️ **AWS** | IAM users/groups/policies/roles, EC2 service roles, JSON policy documents, Elastic IPs, AWS CLI |
| 🔧 **Git** | Bare repositories, `git init --bare`, server-side remotes |
| 🐳 **Docker** | L1 + L2 tasks, assessment, permissions, exec, images from containers, Dockerfiles, real project |

---

# 🐳 Docker Progress

```text
Docker L1 → Assessment 80% → Docker L2 → Permissions
    → EXEC → Image From Container → Dockerfile
    → Real Project (Hybrid Scanner)
```

> ## ✅ **Structured Docker learning complete. Now in application phase.**

---

# ☁️ AWS IAM Progress

```text
User → Group → Policy → Attach Policy → Role → EC2 Service Role
```

> IAM is becoming a **connected access-control system**, not a list of commands. Now working with **JSON policy documents**.

---

# 🌐 Web Infrastructure Progress

Three patterns mastered this week:

```text
Apache → Custom Ports → DocumentRoot → Permissions
Nginx  → Load Balancing → Apache Backends
Nginx  → Unix Socket → PHP-FPM → PHP App
```

> Web infrastructure is now a **system of connected services**, not isolated tools.

---

# 🔧 Troubleshooting Lessons

> ### 🟠 Apache → **Validate before restarting** (`httpd -t`).
>
> ### 🟢 Nginx + PHP-FPM → **Both services need compatible config.**
>
> ### 🔵 AWS IAM → **Identifier (ARN) matters as much as the command.**

---

# 📚 Certification Milestones

> ## 🐳 **Docker L1 — 80% ✅**
>
> ## 🐧 **Linux L1 — 86% ✅**

Both were **practical, hands-on assessments** — not multiple choice.

---

# 🧠 Biggest Lessons

1. **Validate before restarting** — `httpd -t` prevents downtime.
2. **Permissions are part of config** — valid config still fails on wrong ownership.
3. **IAM is a connected system** — User → Group → Policy → Role.
4. **Docker moved from learning → application** — the Hybrid Scanner Dockerfile is the milestone.
5. **Git is infrastructure** — bare repos are server-side remotes.
6. **Troubleshooting is repeatable:**

```text
Understand → Configure → Validate → Test
    → Identify → Investigate → Fix → Verify
```

7. **Consistency ≠ perfection.** A power outage skipped one task. Continue anyway.

---

# 📊 Week 3 Progress

| Area | Status |
|---|---|
| DevOps Days | 🟢 6/7* |
| Cloud Days | 🟢 6/7* |
| Docker L1 | 🟢 80% |
| Docker L2 | 🟢 Completed |
| Hybrid Scanner | 🟢 Dockerfile Created |
| AWS IAM | 🟢 Major Progress |
| Git | 🟢 Bare Repository |
| Web Services | 🟢 Major Progress |
| Troubleshooting | 🟢 Major Progress |

> *Day 15 not documented in the source material.

---

# 🎯 Focus for Week 4

- ☁️ AWS infrastructure
- 🐳 Docker & containerization
- 🔧 DevOps troubleshooting
- 🌐 Networking
- 🐧 Linux administration
- 🔐 IAM & cloud security
- ⚙️ Automation
- 📦 Containerizing my cybersecurity tools

> **Moving from:** *learning individual commands*
> **Moving to:** *understanding how components work together and troubleshooting the entire system.*

---

> # 💡 Week 3 Major Realization
>
> **CloudOps and DevOps aren't about memorizing commands.**
>
> **They're about understanding how systems connect, how resources depend on one another, how to validate changes, and how to troubleshoot the entire chain when something breaks.**

---

<div align="center">

## ✅ **Overall: 🟢 Week 3 — Days 15–21 Completed**

</div>
```

---
