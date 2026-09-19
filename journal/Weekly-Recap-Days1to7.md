````markdown
# Week 1 Recap — CloudOps / DevOps Journey

## Days 1–7 — 13 to 19 September 2026

**Challenges:** KodeKloud 100 Days of DevOps + 100 Days of Cloud (AWS/Azure)

---

# Week 1 Overview

This was my first week of the **100 Days of DevOps** and **100 Days of Cloud** challenges.

My main objective for the week was not just to complete the daily tasks, but to build practical familiarity with Linux administration, AWS, Azure, networking, IAM, security, and infrastructure management.

One decision I made from the beginning was to use the **AWS CLI as much as possible** for my cloud tasks instead of depending entirely on the AWS Management Console.

This meant that some tasks took longer than they would have through the Console, but it forced me to understand resource IDs, command syntax, permissions, dependencies, and troubleshooting.

By the end of Week 1, I had completed **7 consecutive days** of the challenge.

---

# 1. Week 1 Progress

## 100 Days of DevOps

During the first week, I worked through several Linux system administration and automation tasks.

### Concepts Practiced

- Linux users and user management.
- User IDs and home directories.
- File permissions.
- SSH access.
- Shell script execution.
- Cron and scheduled tasks.
- SELinux.
- SSH key-based authentication.
- Password-less SSH.
- `ssh-copy-id`.
- `ssh-agent`.
- Basic Linux service management.
- Troubleshooting permission-related issues.

### Major Tasks Completed

#### Linux Permissions

I worked with Linux file permissions and learned that simply giving a file execute permission does not always mean it can be successfully executed.

One important lesson came from a shell script task where I initially used:

```bash
sudo chmod ugo+x /tmp/xfusioncorp.sh
````

The task failed.

After testing the script, I discovered that the required read permission was also important. I corrected it with:

```bash
sudo chmod ugo+rx /tmp/xfusioncorp.sh
```

This was one of the most useful lessons of the week because it reinforced the importance of **testing instead of assuming**.

---

## Cron

I installed, enabled, and started the cron service on multiple application servers and created cron jobs.

This was my first practical implementation of cron, even though I already understood the concept.

I learned how scheduled automation is used to perform repetitive tasks such as:

* Maintenance.
* Backups.
* Cleanup.
* Monitoring.
* Scheduled scripts.

---

## SELinux

I was introduced practically to **SELinux** while installing the required packages and permanently disabling SELinux on an application server.

This was my first real hands-on experience with SELinux.

I also began understanding the difference between traditional Linux **Discretionary Access Control (DAC)** and **Mandatory Access Control (MAC)**.

---

## SSH Key-Based Authentication

I configured password-less SSH access from a jump host to application servers.

This introduced me practically to:

* SSH key pairs.
* Public and private keys.
* `ssh-copy-id`.
* SSH key permissions.
* `ssh-agent`.
* Private-key protection.
* Security considerations around automated SSH access.

This was also the first time I had to do additional research outside the immediate task to understand how the authentication mechanism worked.

---

# 2. AWS Progress

AWS was a major part of my first week.

Instead of relying mainly on the AWS Management Console, I deliberately used the **AWS CLI** for my personal practice and most cloud challenge tasks.

This exposed me to the actual infrastructure commands behind the console.

---

## IAM

I practiced:

* IAM users.
* IAM groups.
* Access keys.
* Policies.
* Permissions.
* Resource access.

I also encountered an `AccessDenied` error when using a newly created IAM user.

The problem was that the user did not have sufficient permissions.

After granting the required permissions, I was able to continue.

### Lesson

AWS permissions are fundamental.

Having an IAM user does not automatically mean that the user can perform every AWS operation.

---

# 3. EC2

During the week, I practiced several aspects of EC2 management.

### Tasks Included

* Creating EC2 instances.
* Finding AMI IDs.
* Connecting through SSH.
* Modifying instance types.
* Stopping instances.
* Starting instances.
* Terminating instances.
* Working with security groups.
* Working with key pairs.

I also learned that certain EC2 modifications require the instance to be stopped first.

For example:

```text
Find Instance
     ↓
Stop Instance
     ↓
Modify Instance
     ↓
Start Instance
```

---

# 4. AWS Networking

Networking became one of the biggest learning areas during Week 1.

I worked with:

* VPCs.
* Subnets.
* CIDR blocks.
* Security groups.
* Inbound rules.
* Outbound rules.
* Public IP assignment.

### Subnet CIDR Learning

While creating a subnet through the CLI, I encountered invalid CIDR and overlapping subnet issues.

This forced me to understand CIDR more practically.

For example, if the VPC is:

```text
172.31.0.0/16
```

the subnet must be a smaller network contained within that VPC.

I also learned to inspect existing subnets using:

```bash
aws ec2 describe-subnets
```

before choosing a new CIDR range.

This helped me understand that network planning is not simply about entering an IP range that looks correct.

---

# 5. Security Groups

I created and managed security groups through the AWS CLI.

I practiced:

* Authorizing inbound traffic.
* Authorizing outbound traffic.
* Revoking inbound traffic.
* Revoking outbound traffic.

I also learned that security groups act as virtual firewalls for EC2 resources.

A security group rule can define:

* Protocol.
* Port.
* Source.
* Destination.
* Traffic direction.

---

# 6. AWS Storage

I worked with both **S3** and **EBS** during the week.

### S3

I enabled S3 bucket versioning through the AWS CLI.

This helped me understand the concept of object versioning and how it can be managed through the CLI.

### EBS

I created a **gp3 EBS volume** and learned that EBS is block storage designed to be used with compute resources such as EC2.

I also encountered a task failure because I initially omitted a required resource tag.

This reinforced another important lesson:

> Resource configuration requirements matter even when the main resource itself is created successfully.

---

# 7. AMIs

I also learned about **Amazon Machine Images (AMIs)**.

I learned that engineers can create custom AMIs containing predefined configurations and software.

Some reasons for using custom AMIs include:

* Standardization.
* Faster deployment.
* Preinstalled software.
* Repeatable infrastructure.
* Recovery.
* Scaling.

This introduced me to the idea of creating reusable machine templates rather than configuring every server from scratch.

---

# 8. Azure Progress

Although AWS received more of my attention during Week 1, I also completed Azure tasks as part of the Cloud Challenge.

I practiced:

* Azure VM creation.
* Azure CLI.
* SSH key pairs.
* VM configuration.
* Resource groups.
* Ubuntu VM deployment.

One issue I encountered involved creating an SSH key pair during VM creation.

The integrated workflow failed, so I created the key pair separately and then selected it when creating the VM.

This taught me that understanding the individual resources involved in a deployment can make troubleshooting much easier.

---

# 9. My Biggest Troubleshooting Lessons

Week 1 gave me several practical troubleshooting experiences.

### 1. IAM Permission Error

**Problem:**

```text
AccessDenied
```

**Cause:**

The IAM user did not have sufficient permissions.

**Lesson:**

Always check the identity and permissions involved when an AWS API operation is denied.

---

### 2. EC2 SSH Failure

**Problem:**

I could not SSH into an EC2 instance.

**Cause:**

The security group did not allow inbound TCP traffic on port `22`.

**Lesson:**

Successful EC2 deployment does not automatically mean successful remote connectivity.

---

### 3. Shell Script Permission

**Problem:**

The script had execute permission but still could not run correctly.

**Lesson:**

Do not assume a configuration is correct simply because the command completed successfully.

Test the actual operation.

---

### 4. Azure SSH Key Pair

**Problem:**

Key pair creation failed during the VM creation process.

**Solution:**

Create the key pair separately and then use it during VM creation.

**Lesson:**

Breaking a complex deployment into individual resources can simplify troubleshooting.

---

### 5. Subnet CIDR Conflicts

**Problem:**

A proposed subnet CIDR was invalid or conflicted with an existing subnet.

**Solution:**

Inspect the VPC and existing subnets before selecting the CIDR.

**Lesson:**

Networking requires planning and awareness of existing address ranges.

---

### 6. Missing AWS Resource Configuration

**Problem:**

An EBS creation task failed because the required name tag was not included.

**Lesson:**

Cloud resources have configuration requirements beyond simply creating the resource.

---

# 10. What Changed From Day 1 to Day 7?

On Day 1, I was primarily starting the challenge and getting familiar with the environment.

By Day 7, I had already become more comfortable with:

```text
Linux
  ↓
SSH
  ↓
Permissions
  ↓
Services
  ↓
Automation
  ↓
IAM
  ↓
EC2
  ↓
Networking
  ↓
Storage
  ↓
Security
  ↓
AWS CLI
```

The biggest difference is that I am beginning to think in terms of **infrastructure and dependencies** rather than individual commands.

For example:

An EC2 instance is not just an instance.

It can involve:

```text
AMI
 │
 ├── VPC
 │    └── Subnet
 │         └── Route Table
 │
 ├── Security Group
 │
 ├── Key Pair
 │
 ├── IAM
 │
 └── EBS
```

Understanding these relationships will become increasingly important as I move into more advanced AWS and DevOps topics.

---

# 11. CLI Development

One of my personal goals throughout this challenge is to become highly comfortable with the command line.

During Week 1, I practiced commands involving:

### AWS

```bash
aws iam
aws ec2
aws s3
aws sts
```

### Linux

```bash
chmod
systemctl
crontab
ssh
ssh-copy-id
ssh-agent
```

I am intentionally using CLI commands even when the AWS Console would be easier because I want to understand how infrastructure is actually managed through automation and command-line tooling.

---

# 12. Mistakes I Made

I want to document the mistakes because they are part of the learning process.

### Mistake 1 — Not Verifying

I submitted a task after running the required command without properly testing the result.

This caused a failed submission.

### Mistake 2 — Relying on Assumptions

In some situations, I assumed that a configuration was correct because the command itself completed successfully.

Week 1 taught me:

> **Command success does not always equal task success.**

### Mistake 3 — Networking Knowledge Gaps

The subnet CIDR problems showed me that I need to become much stronger with networking fundamentals.

This is something I will continue improving throughout the challenge.

---

# 13. Week 1 Skills Matrix

| Skill                  | Week 1 Status          |
| ---------------------- | ---------------------- |
| Linux Administration   | 🟢 Practiced           |
| Linux Permissions      | 🟢 Practiced           |
| SSH                    | 🟢 Practiced           |
| SSH Key Authentication | 🟢 Practiced           |
| Cron                   | 🟢 Practiced           |
| SELinux                | 🟢 Introduced          |
| IAM                    | 🟢 Practiced           |
| EC2                    | 🟢 Practiced           |
| AMIs                   | 🟢 Learned             |
| Security Groups        | 🟢 Practiced           |
| VPC                    | 🟢 Practiced           |
| Subnets                | 🟢 Practiced           |
| CIDR                   | 🟡 Needs More Practice |
| EBS                    | 🟢 Practiced           |
| S3                     | 🟢 Practiced           |
| AWS CLI                | 🟢 Practiced           |
| Azure CLI              | 🟢 Practiced           |
| Azure VM               | 🟢 Practiced           |
| Troubleshooting        | 🟢 Practiced           |

---

# 14. Week 1 Reflection

The biggest lesson from my first week is that **hands-on practice exposes gaps that theory alone does not reveal**.

I already knew what concepts like SSH, IAM, EC2, security groups, subnets, cron, and AMIs were before encountering some of these tasks.

However, actually configuring them exposed details that I would not have fully understood by simply reading about them.

For example:

* Knowing what SSH keys are is different from actually configuring key-based authentication.
* Knowing what a security group is is different from troubleshooting an SSH connection blocked by port 22.
* Knowing what a subnet is is different from dealing with CIDR conflicts.
* Knowing what Linux permissions are is different from debugging a script that cannot execute.
* Knowing what IAM is is different from encountering `AccessDenied` because of an incorrect permission configuration.

These practical failures were some of the most valuable parts of Week 1.

---

# 15. Goals for Week 2

Going into Week 2, I want to focus on:

* Becoming faster with AWS CLI commands.
* Improving my networking and CIDR knowledge.
* Getting better at verifying configurations after making changes.
* Understanding AWS resource relationships more deeply.
* Continuing the 100 Days of DevOps tasks.
* Continuing the AWS Cloud Challenge.
* Increasing my Azure CLI exposure.
* Documenting every important mistake and troubleshooting lesson.
* Beginning to think more about automation rather than manual configuration.

My goal is not simply to reach Day 100.

My goal is to reach Day 100 with enough practical understanding that I can build, troubleshoot, secure, automate, and explain the infrastructure I am working with.

---

# Week 1 Final Status

| Challenge          | Progress     |
| ------------------ | ------------ |
| 100 Days of DevOps | ✅ Day 7/100  |
| 100 Days of Cloud  | ✅ Day 7/100  |
| AWS                | 🟢 Active    |
| Azure              | 🟢 Active    |
| Linux              | 🟢 Active    |
| CLI Practice       | 🟢 Active    |
| Troubleshooting    | 🟢 Improving |
| Documentation      | 🟢 Active    |

## Week 1: ✅ Completed

> **Week 1 realization:**
> **I don't just want to know the commands. I want to understand what the commands are actually doing, why they sometimes fail, how the resources depend on each other, and how to troubleshoot them when they do.**

---

**Next:** Day 8 → Continue building the foundation.

```
```
