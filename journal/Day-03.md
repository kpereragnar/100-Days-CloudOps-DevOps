# CloudOps / DevOps Journal

> **Day 3 — 15 September 2026**

---

## 100 Days of DevOps Challenge

### Task

Disable SSH root login on three application servers.

**Status:** ✅ Completed

**Issues Encountered:** None.

I was already familiar with the task, so I was able to complete it without encountering any significant issues.

### Lesson Learned

The task reinforced my understanding of Linux SSH configuration and basic server hardening.

---

## 100 Days of Cloud Challenge

### Azure

#### Task

The Azure task required creating an Azure Virtual Machine using the Azure CLI with the following specifications:

| Configuration        | Requirement      |
| -------------------- | ---------------- |
| VM Name              | `xfusion-vm`     |
| Image                | `Ubuntu2204`     |
| VM Size              | `Standard_B2s`   |
| Admin Username       | `azureuser`      |
| Authentication       | SSH keys         |
| Storage Account Type | `Standard_LRS`   |
| Disk Size            | `30 GB`          |
| Final State          | Running          |

#### Issue Encountered

While creating the VM using the Azure CLI, I received an error because I had not specified a resource group.

I initially omitted the resource group because it was not explicitly included in the task requirements.

#### Solution

I listed the available resource groups using:

```bash
az group list
```

I then identified the appropriate resource group and used it during the VM creation process.

#### Lesson Learned

Azure resources are organized within resource groups, and understanding this resource hierarchy is important when working with Azure CLI.

---

### AWS

#### Task

The AWS task required creating a subnet under the default VPC.

The task did not specify a particular subnet name or whether the AWS Management Console or CLI should be used.

#### My Initial Approach

I decided to challenge myself by using the AWS CLI instead of the GUI.

However, I encountered several issues while attempting to complete the task through the CLI.

I eventually switched to the AWS Management Console.

#### Additional Issues

While using the GUI, I encountered two additional problems:

1. The subnet I initially selected was not associated with the intended VPC.
2. I encountered a subnet CIDR overlap error because the CIDR range I wanted to use conflicted with an existing subnet.

I reviewed the existing configuration and found a workaround that allowed me to successfully create the subnet.

#### Lesson Learned

This task reinforced the importance of understanding:

- VPCs
- Subnets
- CIDR ranges
- Subnet associations
- CIDR overlap

It also showed me that I still need more practice with AWS CLI networking commands.

---

## Personal Cloud Practice — AWS

Outside the assigned challenge tasks, I decided to practice creating an EC2 instance completely through the AWS CLI.

### Tasks

- Created an EC2 key pair using the AWS CLI.
- Created an EC2 instance using the AWS CLI.
- Attempted to connect to the instance through SSH.

### Issue Encountered

I successfully created the key pair and EC2 instance, but I could not initially connect to the instance through SSH.

### Root Cause

I had not configured the security group to allow inbound SSH traffic on:

```text
TCP/22
```

### Solution

I modified the security group to allow SSH traffic and was then able to proceed with the connection.

### SSH Key Security

I also learned that a `.pem` private key needs restrictive file permissions before it can be used for SSH authentication on Linux.

For example:

```bash
chmod 400 my-key.pem
```

This prevents other users on the system from having inappropriate access to the private key.

---

## Important Realization — Challenge Structure

During Day 3, I realized that I had misunderstood the structure of the **100 Days of Cloud Challenge**.

I initially thought that the AWS and Azure tracks were supposed to be completed simultaneously.

After reviewing the challenge structure, I understood that the 100-day Cloud Challenge is divided into:

- **50 Days of AWS**
- **50 Days of Azure**

Together, these make the 100-day Cloud Challenge.

### Why This Matters

Working on both AWS and Azure simultaneously was beginning to mix the commands, syntax, resource structures, and concepts in my head.

For example:

```text
AWS CLI   → aws ...
Azure CLI → az ...
```

Although both platforms provide similar cloud services, their CLI syntax, resource hierarchy, networking concepts, and terminology differ.

### Decision Going Forward

- I will follow the challenge sequentially rather than mixing both cloud platforms.
- I will complete the AWS portion first and then move to the Azure portion according to the challenge structure.
- I will continue my **100 Days of DevOps Challenge** alongside the Cloud Challenge.

This should allow me to build stronger familiarity with each platform instead of constantly switching between AWS and Azure.

---

## Day 3 Key Takeaways

Today's most important lesson was not just completing the assigned tasks, but identifying how I learn most effectively.

### Technical Lessons

- Azure VMs require an appropriate resource group.
- AWS subnets must belong to the correct VPC.
- Subnet CIDR ranges cannot overlap.
- EC2 security groups control inbound SSH access.
- SSH private keys require restrictive permissions.
- AWS and Azure CLI syntax are completely different.

### Learning Process Lesson

I realized that attempting to learn AWS and Azure simultaneously was causing unnecessary context switching.

Going forward, I will focus on one cloud provider at a time while continuing the DevOps challenge.

---

## Day 3 Status

| Area                      | Status                 |
| ------------------------- | ---------------------- |
| 100 Days DevOps Challenge | ✅ Completed           |
| Cloud Challenge           | ✅ Completed           |
| AWS Practice              | ✅ Completed           |
| Azure Practice            | ✅ Completed           |
| AWS CLI                   | 🟡 Needs More Practice |
| Azure CLI                 | 🟢 Practiced           |
| AWS Networking            | 🟢 Practiced           |
| EC2 SSH                   | 🟢 Troubleshot         |

**Overall:** 🟢 Day 3/100 — Completed

**Major realization:** Better to master one cloud platform at a time than mix both simultaneously.

