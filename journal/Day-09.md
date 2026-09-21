````markdown
# CloudOps / DevOps Journal

## Day 9 — 21 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task

I was tasked with troubleshooting a **MariaDB server** on the Stratos Datacenter database server.

The MariaDB service was not running, so I had to identify the cause and restore the service.

### Troubleshooting Approach

I started by attempting to start the MariaDB service:

```bash
sudo systemctl start mariadb
````

The service failed to start.

Instead of repeatedly attempting to start it, I checked the service status to investigate the reason for the failure:

```bash
sudo systemctl status mariadb
```

The status output showed a **permission-related issue**. MariaDB was unable to write to its data directory:

```text
/var/lib/mysql
```

### Investigating the Directory

I then checked the ownership and permissions of the directory:

```bash
ls -ld /var/lib/mysql
```

The directory did not have the correct ownership for the MariaDB service.

### Fix

I changed the ownership of the MariaDB data directory to the `mysql` user and group:

```bash
sudo chown -R mysql:mysql /var/lib/mysql
```

I then started MariaDB again:

```bash
sudo systemctl start mariadb
```

This time, the service started successfully.

### Troubleshooting Process

The troubleshooting process was:

```text
Attempt to Start Service
        ↓
Service Failed
        ↓
Check systemctl status
        ↓
Identify Permission Issue
        ↓
Inspect /var/lib/mysql
        ↓
Correct Ownership
        ↓
Restart MariaDB
        ↓
Service Started Successfully
```

### Lesson Learned

This was one of the more practical troubleshooting exercises I have encountered so far.

The main lesson was that when a service fails, the correct approach is not to keep retrying the same command. Instead:

> **Start → Observe the error → Investigate → Identify the root cause → Fix → Verify**

I also learned how important file ownership is for Linux services. A service may be correctly installed and configured but still fail if it does not have the required permissions to access its data directories.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

I was tasked with enabling **Termination Protection** for an existing EC2 instance.

Termination protection helps prevent an EC2 instance from being accidentally terminated through the API or management interface.

### Step 1 — Identify the Instance

I first needed the EC2 instance ID.

While working through this task, I also learned a more efficient way to locate AWS resources by combining:

```bash
--filters
```

with:

```bash
--query
```

Instead of retrieving a large amount of information and manually searching through it, I can filter the results and return only the information I need.

For example:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=<instance-name>" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```

This was a useful improvement to my AWS CLI workflow.

### Step 2 — Enable Termination Protection

I then used:

```bash
aws ec2 modify-instance-attribute
```

together with:

```bash
--disable-api-termination
```

Example:

```bash
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --disable-api-termination
```

### Lesson Learned

This task reinforced my understanding of EC2 protection mechanisms.

I also learned that AWS CLI becomes much more powerful when commands such as `--filters` and `--query` are used together.

Instead of simply retrieving information, I can make the CLI return exactly the resource or attribute I need.

This will become increasingly useful as I work with larger AWS environments.

---

## 3. Personal AWS Task — Internet Gateways

For my personal AWS practice, I decided to learn and implement the lifecycle of an **Internet Gateway (IGW)** using the AWS CLI.

I wanted to understand not only how to create an Internet Gateway, but also how it is inspected, attached, detached, and deleted.

---

### 3.1 List Internet Gateways

I started by listing the existing Internet Gateways:

```bash
aws ec2 describe-internet-gateways
```

This allowed me to inspect the Internet Gateways already present in the AWS environment.

---

### 3.2 Create an Internet Gateway

I then created a new Internet Gateway:

```bash
aws ec2 create-internet-gateway
```

This created the Internet Gateway but did not automatically attach it to a VPC.

### Lesson

Creating an Internet Gateway and attaching it to a VPC are separate operations.

---

### 3.3 Detach an Internet Gateway

I practiced detaching an Internet Gateway from a VPC:

```bash
aws ec2 detach-internet-gateway \
  --internet-gateway-id <internet-gateway-id> \
  --vpc-id <vpc-id>
```

This helped me understand that an Internet Gateway can be associated with a VPC and that the association can be removed independently of the Internet Gateway itself.

---

### 3.4 Attach an Internet Gateway

I then practiced attaching an Internet Gateway to a VPC:

```bash
aws ec2 attach-internet-gateway \
  --internet-gateway-id <internet-gateway-id> \
  --vpc-id <vpc-id>
```

### Issue Encountered

I attempted to attach a new Internet Gateway to a VPC that already had an Internet Gateway attached.

The operation failed.

This helped me understand that a VPC cannot simply have multiple Internet Gateways attached to it.

---

### 3.5 Delete an Internet Gateway

Finally, I practiced deleting an Internet Gateway:

```bash
aws ec2 delete-internet-gateway \
  --internet-gateway-id <internet-gateway-id>
```

### Issue Encountered

I also attempted to delete an Internet Gateway while it was still attached to a VPC.

The operation failed.

I learned that the Internet Gateway must first be detached from the VPC before it can be deleted.

The correct lifecycle is:

```text
Create
  ↓
Attach to VPC
  ↓
Use
  ↓
Detach from VPC
  ↓
Delete
```

### Lesson Learned

This exercise helped me understand the relationship between a VPC and its Internet Gateway more practically.

I also learned an important cloud infrastructure principle:

> **Resources often have dependencies, and those dependencies determine the order in which resources can be modified or deleted.**

Understanding these dependencies is important when managing infrastructure through the CLI.

---

# Day 9 — Key Takeaways

## DevOps Lessons

* `systemctl` can be used to manage Linux services.
* `systemctl status` is useful when troubleshooting service failures.
* Linux services depend on correct file ownership and permissions.
* MariaDB requires appropriate ownership of its data directory.
* `chown` can be used to correct file and directory ownership.
* Troubleshooting should focus on identifying the root cause rather than repeatedly retrying commands.

## AWS Lessons

* EC2 termination protection helps prevent accidental instance termination.
* `modify-instance-attribute` can modify EC2 instance attributes.
* `--disable-api-termination` enables termination protection.
* `--filters` can narrow AWS CLI results.
* `--query` can extract only the information required from AWS CLI output.
* Internet Gateways provide a connection point between a VPC and the internet.
* Internet Gateways must be attached to a VPC before they can provide connectivity.
* An Internet Gateway must be detached before it can be deleted.
* Understanding resource dependencies is important when managing cloud infrastructure.

---

# Day 9 Status

| Area                           | Status       |
| ------------------------------ | ------------ |
| 100 Days DevOps Challenge      | ✅ Completed  |
| MariaDB Troubleshooting        | 🟢 Practiced |
| Linux Service Management       | 🟢 Practiced |
| `systemctl`                    | 🟢 Practiced |
| Linux Ownership                | 🟢 Practiced |
| `chown`                        | 🟢 Practiced |
| AWS EC2 Termination Protection | 🟢 Practiced |
| AWS CLI Filtering              | 🟢 Practiced |
| AWS CLI Querying               | 🟢 Practiced |
| Internet Gateway               | 🟢 Practiced |
| Internet Gateway Lifecycle     | 🟢 Practiced |
| VPC Networking                 | 🟢 Practiced |
| Resource Dependencies          | 🟢 Learned   |

**Overall: 🟢 Day 9/100 — Completed**

> **Major realization:** Troubleshooting is becoming one of the most valuable parts of this journey. The goal is not just to know the command that should work, but to understand how to investigate when it doesn't work, identify the dependency or configuration causing the problem, and fix it systematically.

```
```
