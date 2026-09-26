```markdown
# Weekly Recap — Days 8–14

## Week 2: Days 8–14

This week continued to build on the Linux and AWS foundations from Week 1, with more troubleshooting, service management, networking, security, and AWS resource administration.

Unlike the first week, I found myself spending more time troubleshooting actual problems rather than simply completing straightforward tasks.

---

## 📅 Day 8 — Ansible, EC2 Stop Protection & Linux Administration

### 100 Days of DevOps

- Installed **Ansible 4.9.0** on the jump host using `pip3`.
- Verified the installation and ensured it was available for users.

### 100 Days of Cloud — AWS

- Enabled **EC2 stop protection** using the AWS CLI.
- Practiced modifying EC2 instance attributes.

### Personal Practice

Completed 9 Linux L1 tasks covering:

- User management
- File permissions
- SSH security
- Backups
- Script execution
- File manipulation
- Cron access restrictions

### Key Learning

This was a strong Linux administration day and helped reinforce several concepts that had already appeared in the DevOps challenges.

---

## 📅 Day 9 — MariaDB Troubleshooting & Internet Gateways

### 100 Days of DevOps

Troubleshot a MariaDB service that failed to start.

The service reported a permissions/ownership issue with:

```bash
/var/lib/mysql
````

After investigating the directory permissions, I corrected the ownership:

```bash
sudo chown -R mysql:mysql /var/lib/mysql
```

The MariaDB service then started successfully.

### 100 Days of Cloud — AWS

* Enabled **EC2 termination protection**.
* Improved my method of retrieving instance IDs using AWS CLI filters and queries.
* Practiced the complete **Internet Gateway lifecycle**:

  * Create
  * Attach
  * Detach
  * Delete

I also encountered errors when attempting to attach a second Internet Gateway to a VPC and when trying to delete an attached gateway.

### Key Learning

This was another reminder that AWS resources have dependencies and states that must be understood before performing operations.

---

## 📅 Day 10 — Backup Automation, Elastic IPs & Route Tables

### 100 Days of DevOps

Worked on a backup automation task involving:

```text
Application Files
       ↓
Create Backup
       ↓
Compress / ZIP
       ↓
Move to Archive
       ↓
Upload to Storage Server
```

This gave me more practical exposure to Bash scripting and automation.

### 100 Days of Cloud — AWS

Assigned an **Elastic IP** to an EC2 instance.

I practiced identifying the Elastic IP allocation ID using AWS CLI filters and then associating it with the required instance.

### Personal Practice

Learned about **AWS Route Tables** and how they determine where network traffic is sent.

I also completed two Linux L1 tasks:

* Timezone configuration
* Firewall configuration using `firewalld`

The firewall task was particularly useful because I was more familiar with UFW and had to adjust to the `firewalld` workflow.

### Key Learning

AWS networking components are beginning to make more sense as a system rather than as isolated services.

---

## 📅 Day 11 — Tomcat & Elastic Network Interfaces

### 100 Days of DevOps

Installed and configured a **Tomcat web server**.

The task involved:

* Installing Tomcat
* Configuring a different port
* Deploying a `ROOT.war` file

The main challenge was identifying where the web application should be placed.

Coming from Apache, I initially expected:

```bash
/var/www/html
```

After checking the documentation, I discovered Tomcat's web application directory:

```bash
/usr/share/tomcat/webapps
```

### 100 Days of Cloud — AWS

Attached an **Elastic Network Interface (ENI)** to an EC2 instance.

I used AWS CLI filters and queries to retrieve:

* EC2 instance ID
* Network Interface ID

I then attached the ENI to the instance.

### Personal Practice

Completed 2 Linux L1 tasks.

### Key Learning

Documentation becomes especially important when working with unfamiliar technologies. Knowing how Apache works does not mean assuming Tomcat works the same way.

---

## 📅 Day 12 — Apache Troubleshooting & EBS

### 100 Days of DevOps

Troubleshot an Apache server that was not running correctly.

Using the service status, I discovered that another service, **sendmail**, was using the required Apache port.

I stopped the conflicting service and started Apache.

The server then had another issue: it was not accessible from the jump host.

I investigated the firewall rules and added a rule allowing incoming traffic on the required port.

### 100 Days of Cloud — AWS

Attached an **EBS volume** to an EC2 instance.

The workflow involved:

```text
Retrieve Instance ID
        ↓
Retrieve Volume ID
        ↓
Attach Volume
```

### Personal Practice

Completed 2 Linux L1 tasks.

### Key Learning

Troubleshooting often involves multiple layers. Fixing the service itself was only the first step; network/firewall configuration also had to be checked before the application became accessible.

---

## 📅 Day 13 — iptables, AMIs & Linux L1 Certification

### 100 Days of DevOps

Configured `iptables` across the three application servers.

The requirement was to:

* Install `iptables`
* Allow port `3003` only from the Load Balancer
* Block other incoming traffic to that port
* Make the rules persistent across reboots

I configured the rules, including the specific allow rule for the Load Balancer, followed by the rejection rule.

I then saved the rules:

```bash
sudo iptables-save > /etc/sysconfig/iptables
```

and replicated the configuration across the other application servers.

### 100 Days of Cloud — AWS

Created an **AMI** from an existing EC2 instance.

The AMI was named:

```text
devops-ec2-ami
```

I retrieved the instance ID using AWS CLI filters and then used `create-image` to create the AMI.

### Personal Task — Linux L1 Certification

I completed the **KodeKloud Engineer Linux L1 Certification Assessment**.

Unlike a traditional theoretical or multiple-choice exam, the assessment was completely hands-on.

I had **110 minutes** to complete 10 practical Linux administration questions.

### Result

**86/100 — 86%**

I only missed one question.

### Key Learning

The assessment was a good test of practical Linux skills because I had to actually work inside a server environment rather than simply identify the correct answer.

---

## 📅 Day 14 — Apache Troubleshooting, EC2 Termination & Docker

### 100 Days of DevOps

Troubleshot Apache across all three application servers.

I identified **App Server 1** as the server experiencing the issue.

After checking the logs, I discovered that another process was using the port required by Apache.

I stopped the conflicting process and restarted `httpd`.

### 100 Days of Cloud — AWS

Deleted an EC2 instance.

The workflow was:

```text
Retrieve Instance ID
        ↓
Stop Instance
        ↓
Terminate Instance
```

This reinforced the difference between stopping and terminating an EC2 instance.

### Personal Practice

Started working on **KodeKloud Engineer Docker L1**.

Completed 2 Docker L1 tasks.

### Key Learning

The troubleshooting skills I've been developing with Linux are becoming increasingly transferable. The process of identifying the affected server, checking logs, finding the underlying cause, fixing it, and verifying the service is becoming more natural.

---

# 🧠 Week 2 Skills Developed

### Linux & System Administration

* Ansible installation
* MariaDB troubleshooting
* Apache troubleshooting
* Tomcat installation and configuration
* Linux permissions
* Process troubleshooting
* Cron
* Firewall configuration
* iptables
* Service management
* User management
* File manipulation
* Archive management

### AWS

* EC2 stop protection
* EC2 termination protection
* EC2 lifecycle management
* Elastic IPs
* Elastic Network Interfaces
* EBS volumes
* Internet Gateways
* Route Tables
* AMIs
* AWS CLI filtering and querying

### Docker

* Started Docker L1 practical tasks

---

# 🔧 Troubleshooting Lessons

One of the biggest themes of this week was **troubleshooting**.

Several tasks required me to investigate why something wasn't working instead of simply following instructions.

Examples included:

### MariaDB

```text
Service failed
     ↓
Check status
     ↓
Inspect permissions
     ↓
Correct ownership
     ↓
Start service
```

### Apache

```text
Apache not running
       ↓
Check logs/status
       ↓
Find port conflict
       ↓
Stop conflicting process
       ↓
Restart Apache
```

### Apache Network Access

```text
Apache running
       ↓
Still inaccessible
       ↓
Check firewall
       ↓
Allow required port
       ↓
Test connectivity
```

These experiences are making me understand that **troubleshooting is a skill of its own**.

---

# ☁️ AWS CLI Progress

One area where I noticed clear improvement this week was using the AWS CLI.

Instead of manually searching through large outputs, I increasingly used:

```bash
--filters
```

and

```bash
--query
```

For example:

```bash
aws ec2 describe-instances \
--filters "Name=tag:Name,Values=<instance-name>" \
--query "Reservations[].Instances[].InstanceId"
```

This makes the workflow much faster and cleaner.

I'm beginning to develop a consistent pattern:

```text
Identify Resource
       ↓
Retrieve Resource ID
       ↓
Perform Action
       ↓
Verify Result
```

---

# 📚 Certification Milestone

This week also marked my first KodeKloud Engineer certification assessment.

### Linux L1

**Score: 86%**

The assessment was practical rather than theoretical, which made it a useful test of whether I could actually apply the Linux skills I've been practicing.

---

# 🧠 Biggest Lessons From Week 2

### 1. Troubleshooting is becoming more important than memorization

Knowing commands is useful, but understanding **why something failed** is much more valuable.

### 2. Documentation matters

My Tomcat experience was a good example.

I initially approached it using what I knew from Apache, but checking the documentation showed me how Tomcat actually handles application deployment.

### 3. AWS resources have relationships and dependencies

Internet Gateways, route tables, subnets, ENIs, EBS volumes, EC2 instances and security controls are not isolated components.

They work together as part of an infrastructure.

### 4. CLI efficiency matters

Using filters and queries is becoming second nature, and this is making AWS CLI tasks significantly easier.

### 5. Hands-on practice exposes gaps

The biggest value of these tasks is that they force me to actually interact with infrastructure.

Instead of just thinking:

> "I know what this service does."

I'm getting to the point of:

> "I can actually configure it, break it, troubleshoot it and get it working again."

---

# 📊 Week 2 Progress

| Area                   | Progress          |
| ---------------------- | ----------------- |
| DevOps Days            | 🟢 7/7 Completed  |
| Cloud Days             | 🟢 7/7 Completed  |
| Linux L1 Tasks         | 🟢 Completed      |
| Linux L1 Certification | 🟢 86%            |
| Docker L1              | 🟢 Started        |
| AWS CLI                | 🟢 Improving      |
| Troubleshooting        | 🟢 Major Progress |

---

# 🎯 Focus for Week 3

Going into the next week, my focus is to continue improving in:

* Linux administration
* Web server troubleshooting
* AWS infrastructure
* AWS CLI
* Docker
* Automation
* Networking
* Security

Most importantly, I want to continue developing the ability to **understand a problem, investigate it systematically, and solve it without relying on step-by-step instructions every time.**

---

> **Week 2 Major Realization:**
> **The goal isn't just to know the commands. The goal is to understand the system well enough to know what to check when those commands don't work.**

**Overall: 🟢 Week 2 — Days 8–14 Completed**

```

