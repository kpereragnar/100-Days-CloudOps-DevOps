````markdown
# CloudOps / DevOps Journal

## Day 10 — 22 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task

I was tasked with creating a script that automatically:

1. Backs up files on an application server.
2. Compresses the backup into a ZIP archive.
3. Moves the archived backup to an archive directory.
4. Uploads the backup to a storage server.

The objective was to automate the backup and transfer process rather than performing each operation manually.

### Approach

I approached the task by creating a script that handles the required operations in sequence:

```text
Application Files
       ↓
Create Backup
       ↓
Compress / ZIP
       ↓
Move to Archive Directory
       ↓
Upload to Storage Server
````

This task introduced me further to the idea of combining multiple Linux operations into a single automated workflow.

### Lesson Learned

The major lesson from this task was understanding how scripting can turn a series of manual administrative operations into an automated process.

Instead of manually:

* Creating backups.
* Compressing files.
* Moving files.
* Transferring files.

A script can perform the entire workflow automatically.

This is one of the areas where Linux administration begins to connect directly with **DevOps automation**.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

I was tasked with assigning an **Elastic IP address** to an existing EC2 instance.

### Step 1 — Get the Instance ID

First, I identified the EC2 instance that needed the Elastic IP.

I used the AWS CLI to retrieve the required **Instance ID**.

### Step 2 — Get the Elastic IP Allocation ID

I then used `describe-addresses` with a filter and query to locate the Elastic IP:

```bash
aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=datacenter-elastic-ip" \
  --query "Addresses[].AllocationId"
```

This was another opportunity to practice using:

```text
--filters
```

and:

```text
--query
```

to retrieve only the specific information I needed.

The important value was the **Allocation ID** of the Elastic IP.

### Step 3 — Associate the Elastic IP

I then associated the Elastic IP with the EC2 instance using:

```bash
aws ec2 associate-address \
  --allocation-id <allocation-id> \
  --instance-id <instance-id>
```

### Lesson Learned

This task gave me more practical experience working with **Elastic IPs** and reinforced the importance of understanding AWS resource identifiers.

I also continued improving my ability to efficiently locate resources using AWS CLI filters and queries instead of manually searching through large command outputs.

---

# 3. Personal AWS Task — Route Tables

For my personal AWS learning, I decided to study **Route Tables** and how they control traffic within AWS networking.

This was important because I had already been working with:

* VPCs.
* Subnets.
* Internet Gateways.
* Security Groups.
* CIDR blocks.

I wanted to understand how these components work together.

---

## Route Tables

A route table contains rules that determine where network traffic should be sent.

A route can specify:

* A destination CIDR.
* A target.
* Where traffic matching that destination should be routed.

For example:

```text
Destination        Target
0.0.0.0/0          Internet Gateway
10.0.2.0/24        Local / Other Target
```

### Why Route Tables Matter

Route tables are fundamental to AWS networking because they determine how traffic moves between different network destinations.

They can be used to control traffic involving:

* Subnets.
* Internet Gateways.
* NAT Gateways.
* VPC Peering.
* Transit Gateways.
* Other networking targets.

### VPC Peering

I also learned more about how **VPC Peering** works.

For two VPCs to communicate through a VPC peering connection, appropriate routes need to exist so that traffic destined for the other VPC is sent through the peering connection.

This helped me understand that creating a networking connection alone does not necessarily mean that traffic will automatically flow.

The route tables also need to direct the traffic appropriately.

### Lesson Learned

Before this, I was learning AWS networking mostly as individual services.

Now I am beginning to see the bigger picture:

```text
VPC
 │
 ├── Subnets
 │
 ├── Route Tables
 │
 ├── Internet Gateway
 │
 ├── NAT Gateway
 │
 └── VPC Peering
```

Understanding how these components interact is making AWS networking much easier to understand.

---

# 4. Personal Linux Practice — KodeKloud Linux L1

I also completed **2 additional Linux L1 tasks** on KodeKloud.

The tasks covered:

1. Timezone alignment.
2. Firewall configuration using `firewalld`.

---

## 4.1 Timezone Alignment

I completed the timezone alignment task without encountering any major issues.

This gave me additional practice with Linux system configuration and timezone management.

---

## 4.2 Firewall Configuration Using Firewalld

This was my first practical experience configuring a firewall using **firewalld**.

I added the required port to the firewall configuration, but initially did not realize that I needed to reload `firewalld` for the configuration change to take effect.

I am more familiar with **UFW**, where my previous experience did not require me to think about this reload step in the same way.

### Lesson Learned

The task reinforced that different Linux firewall management tools have different workflows.

For example, after making a configuration change with `firewalld`, I need to reload the firewall when appropriate:

```bash
sudo firewall-cmd --reload
```

I also learned to check the active configuration rather than assuming that adding a rule automatically means the running firewall has already applied it.

### Key Difference

My previous experience:

```text
UFW
 ↓
Add rule
 ↓
Apply configuration
```

My new experience:

```text
firewalld
 ↓
Add rule
 ↓
Reload
 ↓
Verify
```

This was a useful reminder that familiarity with one Linux administration tool does not automatically mean every other tool works in exactly the same way.

---

# Day 10 — Key Takeaways

## DevOps Lessons

* Linux scripts can automate multiple administrative operations.
* Backup workflows can be automated instead of performed manually.
* Files can be compressed, archived, and transferred as part of a single workflow.
* Automation reduces repetitive manual operations.
* Different Linux tools can have different configuration and reload requirements.

## AWS Lessons

* Elastic IPs can be associated with EC2 instances.
* `describe-addresses` can be used to retrieve Elastic IP information.
* `--filters` can be used to identify specific AWS resources.
* `--query` can extract specific resource attributes.
* `associate-address` can associate an Elastic IP with an EC2 instance.
* Route tables determine how network traffic is routed.
* VPC Peering requires appropriate routing for communication between VPCs.
* AWS networking components work together rather than operating independently.

## Linux Lessons

* Timezone configuration is part of Linux system administration.
* `firewalld` provides firewall management through `firewall-cmd`.
* Firewall configuration changes may need to be reloaded before taking effect.
* Experience with UFW does not necessarily translate directly to `firewalld`.

---

# Day 10 Status

| Area                       | Status       |
| -------------------------- | ------------ |
| 100 Days DevOps Challenge  | ✅ Completed  |
| Linux Scripting            | 🟢 Practiced |
| Automated Backups          | 🟢 Practiced |
| File Compression           | 🟢 Practiced |
| File Transfer              | 🟢 Practiced |
| AWS Elastic IP             | 🟢 Practiced |
| EC2 Elastic IP Association | 🟢 Practiced |
| AWS CLI Filters            | 🟢 Practiced |
| AWS CLI Queries            | 🟢 Practiced |
| Route Tables               | 🟢 Learned   |
| VPC Routing                | 🟢 Learned   |
| VPC Peering                | 🟢 Learned   |
| Linux Timezone Management  | 🟢 Practiced |
| Firewalld                  | 🟢 Practiced |
| Firewall Configuration     | 🟢 Practiced |

**Overall: 🟢 Day 10/100 — Completed**

> **Major realization:** I am beginning to see how individual AWS networking components fit together. VPCs, subnets, route tables, gateways, and security controls are not isolated services — they work together to determine how traffic moves through the cloud environment.

```
```
