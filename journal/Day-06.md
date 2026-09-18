# CloudOps / DevOps Journal

## Day 6 — 18 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task

Install, enable, and start the **cron** service on three application servers.

Then, create a cron job on each of the three application servers.

### Approach

I connected to the required application servers and completed the following:

- Installed the cron package.
- Enabled the cron service to start automatically.
- Started the cron service.
- Created the required cron job on each server.

### Issues Encountered

No immediate issues were encountered.

Although this was my first time implementing a cron job practically, I already had a basic understanding of what cron jobs are and how they are used.

### New Concept Practiced: Cron Jobs

A **cron job** is a scheduled task in Linux that runs automatically at a specified time or interval.

Cron jobs are commonly used for:

- Running maintenance scripts.
- Creating backups.
- Cleaning temporary files.
- Monitoring systems.
- Sending scheduled reports.
- Automating repetitive administrative tasks.

Cron schedules are commonly configured using:

```bash
crontab -e
```

A cron entry follows this general format:

```text
* * * * * command
│ │ │ │ │
│ │ │ │ └── Day of the week
│ │ │ └──── Month
│ │ └────── Day of the month
│ └──────── Hour
└────────── Minute
```

### Lesson Learned

This task gave me my first practical experience installing and configuring the cron service.

I learned that knowing the concept of a tool is different from actually implementing it on a server. The task helped me understand how scheduled automation is configured and managed in a Linux environment.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

Create an EC2 instance using the AWS CLI.

### Approach

Because I want to become more comfortable with the AWS CLI, I have been using CLI commands to complete the cloud challenge tasks instead of relying primarily on the AWS Management Console.

For this task, I created the EC2 instance through the AWS CLI.

### Issue Encountered

The main difficulty was finding the correct **AMI Image ID** required for the instance.

I had to access the AWS Management Console, locate the appropriate image, and copy its Image ID before continuing with the CLI command.

### Example Command Structure

An EC2 instance can be created using a command similar to:

```bash
aws ec2 run-instances \
  --image-id <ami-image-id> \
  --instance-type <instance-type> \
  --key-name <key-pair-name> \
  --security-group-ids <security-group-id> \
  --subnet-id <subnet-id> \
  --count 1
```

The actual values depend on the requirements of the task and the AWS region being used.

### Lesson Learned

I learned that the AMI Image ID is an important requirement when launching an EC2 instance through the CLI.

I also realized that becoming comfortable with the AWS CLI requires knowing how to locate resource identifiers such as:

- AMI IDs.
- VPC IDs.
- Subnet IDs.
- Security Group IDs.
- Key Pair names.
- Instance IDs.

Although I used the Console to locate the AMI ID, the instance creation itself was completed through the CLI.

---

## 3. Personal Cloud Practice — AWS

### Tasks

I created a new security group using the AWS CLI.

I also practiced how to:

- Authorize inbound traffic.
- Authorize outbound traffic.
- Revoke inbound traffic.
- Revoke outbound traffic.

### Security Groups

An AWS **security group** acts as a virtual firewall for resources such as EC2 instances.

Security groups control network traffic using rules that specify:

- Traffic direction.
- Protocol.
- Port or port range.
- Source or destination.
- IP address or security group reference.

### CLI Operations Practiced

#### Authorize Inbound Traffic

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 22 \
  --cidr <cidr-block>
```

This adds an inbound rule to a security group.

#### Authorize Outbound Traffic

```bash
aws ec2 authorize-security-group-egress \
  --group-id <security-group-id> \
  --ip-permissions <ip-permissions>
```

This adds an outbound rule to a security group.

#### Revoke Inbound Traffic

```bash
aws ec2 revoke-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 22 \
  --cidr <cidr-block>
```

This removes an inbound rule from a security group.

#### Revoke Outbound Traffic

```bash
aws ec2 revoke-security-group-egress \
  --group-id <security-group-id> \
  --ip-permissions <ip-permissions>
```

This removes an outbound rule from a security group.

### Lesson Learned

This practice helped me understand how AWS security groups are managed through the CLI.

I learned that security group rules can be added and removed as needed, allowing administrators to control which traffic is permitted to reach or leave an EC2 instance.

---

# Day 6 — Key Takeaways

## Technical Lessons

- Cron is used to schedule recurring tasks on Linux systems.
- The cron service must be installed, enabled, and started before scheduled jobs can run.
- `crontab -e` is commonly used to create or edit cron jobs.
- EC2 instances can be created using the `aws ec2 run-instances` command.
- An AMI Image ID is required when launching an EC2 instance through the CLI.
- AWS CLI workflows often require locating resource identifiers.
- Security groups act as virtual firewalls for EC2 instances.
- Inbound rules control traffic entering a resource.
- Outbound rules control traffic leaving a resource.
- AWS CLI provides commands for authorizing and revoking security group rules.

## Personal Learning Lesson

Today's tasks helped me move from simply understanding concepts to implementing them practically.

I gained hands-on experience with Linux cron jobs, EC2 provisioning through the AWS CLI, and security group traffic management.

The biggest lesson was:

> The more I use the CLI to create and manage resources, the more comfortable I become with cloud infrastructure and resource configuration.

---

## Day 6 Status

| Area | Status |
|---|---|
| 100 Days DevOps Challenge | ✅ Completed |
| AWS Cloud Challenge | ✅ Completed |
| Cron Installation | 🟢 Practiced |
| Cron Service Management | 🟢 Practiced |
| Cron Job Configuration | 🟢 Practiced |
| AWS EC2 Provisioning | 🟢 Practiced |
| AMI Identification | 🟢 Practiced |
| AWS CLI | 🟢 Practiced |
| Security Group Creation | 🟢 Practiced |
| Inbound Rule Management | 🟢 Practiced |
| Outbound Rule Management | 🟢 Practiced |
| Security Rule Revocation | 🟢 Practiced |

**Overall: 🟢 Day 6/100 — Completed**

**Major realization:** Practical implementation builds confidence and makes cloud concepts easier to understand.

