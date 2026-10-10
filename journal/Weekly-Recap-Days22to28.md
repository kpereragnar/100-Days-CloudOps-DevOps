# 📊 Weekly Recap — Days 22–28

[![Week](https://img.shields.io/badge/week-4-blue)](#)
[![Days](https://img.shields.io/badge/days-22--28-green)](#)
[![Status](https://img.shields.io/badge/status-completed-brightgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 4: Days 22–28

> **Week 4 moved beyond individual commands into connecting infrastructure, automating server configuration, monitoring workloads, and managing container images.**

Covered: **Git, AWS EC2, S3, IAM, Application Load Balancers, VPC networking, CloudWatch, SNS, Ansible L1/L2, Docker, and Amazon ECR.**

> 🔑 **Theme of the week:** understand the dependencies, use the right workflow, and verify the result instead of assuming a command has completed the entire task.

---

## 📅 Day 22 — Git Cloning, EC2 Access & Ansible

### 🛠️ DevOps

Cloned a Git repository, reinforcing the Git L1 and L2 concepts I had already practised.

### ☁️ AWS

Created an EC2 instance named `datacenter-ec2` and configured SSH access from `aws-client`.

The task involved:

* Creating an EC2 key pair.
* Launching the instance.
* Troubleshooting SSH connection failures.
* Checking the security group and opening inbound SSH port 22.
* Configuring root SSH access and passwordless authentication.

> 💡 **An SSH key alone does not guarantee connectivity.** Network reachability and security group rules must also be correct.

### ⚙️ Ansible

Completed additional Ansible L1 tasks involving troubleshooting, playbook creation, and inventory configuration for app server testing.

---

## 📅 Day 23 — Git Forking, S3 Migration & Ansible L1 Completion

### 🛠️ DevOps

Forked a Git repository using the GUI. Previous Git L1 and L2 practice made the task straightforward.

### ☁️ AWS — S3 Migration

Migrated data between two S3 buckets using the AWS CLI.

The workflow included:

* Verifying my AWS identity with `aws sts get-caller-identity`.
* Inspecting source objects and total size.
* Creating the destination bucket.
* Enabling S3 Block Public Access.
* Migrating objects with `aws s3 sync`.
* Verifying the destination contents.

```bash
aws s3 sync s3://source-bucket/ s3://destination-bucket/
```

> 💡 **A migration is not complete just because the command finishes.** Verify the destination objects and compare the results with the source.

### ⚙️ Ansible L1 — Completed

Completed the remaining Ansible L1 tasks and finished the structured challenge.

Topics reinforced:

* INI inventories and host variables.
* Ad-hoc commands and playbooks.
* Ansible configuration and SSH defaults.
* YAML syntax and indentation.
* Idempotency and the `file` module.
* Troubleshooting inventory and variable errors.

> 🏆 Milestone: Ansible L1 completed.

---

## 📅 Day 24 — Git Branching, Application Load Balancer & Ansible L1 Assessment

### 🛠️ DevOps — Git Branching

Practised the standard branching workflow:

```bash
git checkout -b feature-branch
git add .
git commit -m "feat: add new feature"
git checkout main
git merge feature-branch
git branch -d feature-branch
```

Because of my previous Git L1 and L2 practice, the task was routine.

> 💡 **Consistency beats memorization.** Repeated practice turns previously unfamiliar commands into a familiar workflow.

### ☁️ AWS — Application Load Balancer

Created an Application Load Balancer named `datacenter-alb`, a target group named `datacenter-tg`, and a security group named `datacenter-sg`.

The task required HTTP traffic on port 80 to reach the `datacenter-ec2` instance.

My first attempt returned `503 Service Unavailable`. Although the ALB and target group existed, the traffic path was incomplete.

I identified three missing pieces:

* A listener connecting the ALB to the target group.
* Target registration for the EC2 instance.
* An EC2 security group rule allowing HTTP traffic from the ALB's security group.

After connecting the resources and allowing the required traffic, the ALB returned `200 OK`.

```text
Client
  |
  v
Application Load Balancer
  |
  v
Listener — HTTP :80
  |
  v
Target Group
  |
  v
EC2 Instance — HTTP :80
```

> 💡 **Creating resources is not the same as connecting them.** A working application path requires a listener, healthy registered targets, and appropriate security group rules.

### ⚙️ Ansible L1 Assessment — 100%

Completed the KodeKloud Engineer Ansible L1 Certification Assessment.

* 10 practical tasks.
* 120 minutes.
* 100% score.
* Passing score: 80%.

The assessment covered inventories, host variables, the `copy` module, file permissions, Ansible configuration, localhost, package installation, and troubleshooting.

Key lessons included:

* YAML indentation determines structure.
* Inventory variables require the correct syntax, such as `ansible_user=tony`.
* The `file` module uses `state: touch`, not a `touch` parameter.
* `ansible-doc -s <module>` helps identify valid module parameters.
* Per-host variables allow one playbook to produce different results on different servers.

> 🏆 Milestone: Ansible L1 assessment completed with 100%.

---

## 📅 Day 25 — Git Branches, EC2 & CloudWatch Alarms

### 🛠️ DevOps — Branching, Merging & Pushing

Created a feature branch, committed `index.html`, merged the branch into `master`, and pushed both branches to the remote repository.

```bash
git checkout master
git checkout -b xfusion

git add index.html
git commit -m "Add index.html"

git checkout master
git merge xfusion

git push -u origin xfusion
git push origin master
```

My first attempt used `git push -u origin`, assuming it would push both branches. Checking the remote revealed that `origin/xfusion` was missing.

> 💡 **A successful push does not mean every local branch has been pushed.** Explicitly name the branches or use `git push --all origin` when appropriate.

### ☁️ AWS — CloudWatch & SNS

Launched an EC2 instance named `xfusion-ec2` and created a CloudWatch alarm named `xfusion-alarm`.

The alarm configuration included:

* Metric: `CPUUtilization`
* Statistic: `Average`
* Period: 300 seconds
* Threshold: 90%
* Comparison: `GreaterThanOrEqualToThreshold`
* Evaluation periods: 1
* Datapoints to alarm: 1
* Alarm action: SNS topic notification

> 💡 **Monitoring configuration requires precision.** Five minutes is 300 seconds, and `>=` differs from `>`.

This task reinforced how CloudWatch evaluates metrics and how SNS can be configured as an alarm action.

---

## 📅 Day 26 — Git Remotes, EC2 User-Data & Passwordless SSH

### 🛠️ DevOps — Add a New Git Remote

Added a remote named `dev_blog` pointing to `/opt/xfusioncorp_blog.git`, committed `index.html` to `master`, and pushed the branch to the new remote.

```bash
git remote add dev_blog /opt/xfusioncorp_blog.git
git remote -v

git add index.html
git commit -m "Add index.html"

git push dev_blog master
```

The key lesson was that the task's use of the word “origin” did not mean I should push to the existing remote literally named `origin`.

> 💡 **Check `git remote -v` before pushing.** The correct destination depends on the remote configured for the task.

### ☁️ AWS — EC2 User-Data

Launched an EC2 instance named `datacenter-ec2` with a user-data script that installed and started Nginx.

```bash
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
```

Configured the security group to allow inbound HTTP traffic on port 80. After the instance started, tested its public IP with `curl` and received `HTTP/1.1 200 OK`.

Key lessons:

* User-data can bootstrap software during the first instance boot.
* The package manager must match the operating system.
* `--user-data file:///tmp/userdata.sh` passes a local script file to the EC2 launch command.
* The service must be running, and the security group must permit HTTP traffic.

### ⚙️ Ansible — Passwordless SSH

Configured key-based SSH from `thor@jump-host` to `banner@stapp03`.

```bash
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
ssh-copy-id banner@stapp03
ssh banner@stapp03 "hostname"
```

Updated the Ansible inventory to use the appropriate SSH users, removed password-based inventory entries, and tested connectivity:

```bash
ansible stapp03 -i inventory -m ping
```

The result was successful: `ping: pong`.

> 💡 **Passwordless SSH means key-based authentication, not simply disabling password prompts.** The private key stays on the controller, while the public key is installed on the target.

---

## 📅 Day 27 — Git Revert, Public VPC & Ansible L2

### 🛠️ DevOps — Git Revert

Reverted the latest commit in the `ecommerce` repository using the exact required commit message.

```bash
git revert --no-commit HEAD
git commit -m "revert ecommerce"
```

> 💡 `git revert` creates a new commit that undoes a previous commit without erasing the existing history.

### ☁️ AWS — Public VPC Networking

Created a VPC, subnet, security group, and EC2 instance. My first attempt was incomplete because I had not configured the full internet path.

The missing pieces included:

* An Internet Gateway attached to the VPC.
* A route for `0.0.0.0/0` through the Internet Gateway.
* A route table associated with the subnet.
* Automatic public IPv4 assignment on the subnet.

```text
Internet
   |
Internet Gateway
   |
Route Table — 0.0.0.0/0 → IGW
   |
Public Subnet
   |
Public IPv4 + Security Group
   |
EC2 Instance
```

> 💡 **A public subnet is a networking configuration, not just a security group setting.** Routing, public IP assignment, and traffic rules must work together.

### ⚙️ Ansible L2 — Completed

Completed two practical playbooks.

**Task 1: Extract an archive**

* Extracted `xfusion.zip` to `/opt/finance/` across all app servers.
* Used `unarchive` to extract files and set ownership and permissions.

**Task 2: Install and configure HTTPD**

* Installed `httpd`.
* Ensured the service was started and enabled.
* Used `blockinfile` to add the required content to `index.html`.
* Set file ownership and permissions.
* Retained the default block markers.

> 🏆 Milestone: Ansible L2 completed.

---

## 📅 Day 28 — Git Cherry-Pick, Docker Build & Amazon ECR

### 🛠️ DevOps — Git Cherry-Pick

Practised applying a specific commit from one branch to another.

```bash
git log --oneline
git checkout <target-branch>
git cherry-pick <commit-hash>
```

> 💡 **Cherry-pick is selective; merge is inclusive.** Cherry-pick applies a particular commit without merging the entire source branch.

### ☁️ AWS — Amazon ECR

Created a private ECR repository named `xfusion-ecr`, built a Docker image from `/root/pyapp`, tagged it for ECR, authenticated Docker, and pushed the image with the `latest` tag.

### 🐳 Troubleshooting Docker Build Context

My first attempt used:

```bash
docker build -t app:latest < Dockerfile
```

This did not provide the project directory as the normal build context, so required files such as `requirements.txt` were unavailable to the build.

The corrected command was:

```bash
cd /root/pyapp
docker build -t app:latest .
```

The `.` specifies the current directory as the build context.

### ECR Workflow

```text
Create ECR Repository
        |
        v
Build Docker Image
        |
        v
Authenticate Docker to ECR
        |
        v
Tag Image with ECR URI
        |
        v
Push Image to ECR
```

The image URI follows this pattern:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
```

> 💡 **Docker builds the image; ECR stores it.** This is a foundational step toward container deployment and future CI/CD workflows.

---

# 🧠 Skills Developed

| Area                      | Highlights                                                                                               |
| ------------------------- | -------------------------------------------------------------------------------------------------------- |
| 🌿 **Git**                | Branching, merging, pushing multiple branches, remotes, reverting, cherry-picking                        |
| ☁️ **AWS Compute**        | EC2 provisioning, key pairs, SSH, user-data                                                              |
| 🌐 **AWS Networking**     | ALB, target groups, listeners, VPCs, subnets, Internet Gateways, route tables, security groups           |
| 🔐 **AWS Security & IAM** | Identity verification, access rules, S3 Block Public Access, SSH key authentication                      |
| 🪣 **AWS Storage**        | S3 bucket creation, synchronization, migration                                                           |
| 📊 **Monitoring**         | CloudWatch CPU alarms, evaluation periods, SNS alarm actions                                             |
| ⚙️ **Ansible**            | L1 assessment, L2 playbooks, inventories, host variables, `unarchive`, `blockinfile`, service management |
| 🐳 **Docker & ECR**       | Build context, image tagging, registry authentication, private ECR image push                            |

---

# ⚙️ Ansible Progress

```text
Ansible L1 Assessment — 100%
             |
             v
Inventories & Host Variables
             |
             v
Ad-hoc Commands & Playbooks
             |
             v
Passwordless SSH
             |
             v
Ansible L2 Playbooks
             |
             v
Archive Extraction & File Permissions
             |
             v
HTTPD Configuration
```

> 🏆 **Ansible L1 and L2 completed.**

The focus is shifting from learning syntax to applying automation across multiple servers and managing their desired state.

---

# ☁️ AWS Progress

```text
EC2 & SSH
   |
   v
User-Data & Nginx
   |
   v
S3 Migration
   |
   v
Application Load Balancer
   |
   v
CloudWatch + SNS
   |
   v
VPC + Public Subnet + Internet Gateway
   |
   v
Docker Image → Amazon ECR
```

> **AWS is becoming a connected system of compute, networking, storage, monitoring, and container services.**

The goal is to understand how these services depend on one another rather than treating each CLI command as an isolated task.

---

# 🔧 Troubleshooting Lessons

1. **Verify Git remotes and branches.** A local branch is not necessarily on the remote, and the wrong remote can receive a push.
2. **SSH requires a complete connection path.** Keys, public IPs, security groups, and routing all matter.
3. **An ALB needs connected components.** A listener, registered healthy targets, and appropriate security group rules are essential.
4. **A public subnet requires routing.** Attach the Internet Gateway, add the default route, associate the route table, and configure public IP assignment.
5. **CloudWatch settings must match the requirement.** Check comparison operators, periods, evaluation periods, and alarm actions.
6. **Ansible modules have specific responsibilities.** Use `unarchive` for archives and `blockinfile` for managed content blocks.
7. **Docker build context matters.** A valid Dockerfile is not enough if required files are outside the build context.
8. **Verify the outcome.** Check remote branches, test the HTTP endpoint, run Ansible ping, and inspect destination resources.

The troubleshooting workflow I'm reinforcing:

```text
Understand the requirement
          |
          v
Inspect the current state
          |
          v
Map the dependencies
          |
          v
Configure one component at a time
          |
          v
Validate and test
          |
          v
Verify the final result
```

---

# 📊 Week 4 Progress

| Area                          | Status                  |
| ----------------------------- | ----------------------- |
| DevOps Days                   | 🟢 7/7                  |
| Cloud Days                    | 🟢 7/7                  |
| Ansible L1                    | 🟢 100% assessment      |
| Ansible L2                    | 🟢 Completed            |
| Git Workflows                 | 🟢 Expanded             |
| AWS Application Load Balancer | 🟢 Completed            |
| AWS Public VPC                | 🟢 Completed            |
| AWS S3 Migration              | 🟢 Completed            |
| CloudWatch + SNS              | 🟢 Configured           |
| Docker → Amazon ECR           | 🟢 Image push completed |
| Troubleshooting               | 🟢 Major progress       |

---

# 🎯 Focus for Week 5

* ☁️ Continue building practical AWS infrastructure skills.
* 🐳 Continue containerizing my cybersecurity tools, starting with Hybrid Scanner.
* ⚙️ Progress toward Terraform and Infrastructure as Code.
* 🔄 Build toward CI/CD and repeatable container deployment workflows.
* 🔐 Strengthen AWS IAM, networking, monitoring, and cloud security.
* 📁 Keep documenting daily tasks and turning the lessons into portfolio-ready projects.

---

# 💡 Week 4 Major Realization

> **Infrastructure is a chain of dependencies, and every link matters.**
>
> An ALB can exist without successfully routing traffic. An EC2 instance can run without being reachable from the internet. A Git branch can exist locally without being pushed to the remote. A Dockerfile can be correct while the build still fails because required files are missing from the context.
>
> The recurring lesson is to understand the complete workflow, verify each dependency, and test the final result instead of assuming that a successful command means the whole task is complete.

---

<div align="center">

## ✅ Overall: 🟢 Week 4 — Days 22–28 Completed

**28/100 Days Complete**

</div>

