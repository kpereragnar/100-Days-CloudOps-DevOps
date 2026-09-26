````markdown
# CloudOps / DevOps Journal

## Day 14 — 26 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Troubleshoot Apache Across Multiple App Servers

I was tasked with troubleshooting a running Apache service across all three application servers.

I checked the servers to identify which one was experiencing the issue.

After investigating, I found that **App Server 1** was the server with the problem.

I checked the Apache logs and discovered that another process was already using the port required by Apache.

I stopped the conflicting process and restarted the Apache service:

```bash
sudo systemctl restart httpd
````

After restarting Apache, the service was running properly.

### Lesson Learned

This was another good reminder that checking the logs can quickly point to the actual cause of a service failure.

A service may appear to have a problem, but the underlying issue can be another process occupying a required resource such as a port.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Delete an EC2 Instance

I was tasked with deleting an existing EC2 instance.

I first retrieved the instance ID of the required EC2 instance.

I then stopped the instance before terminating it:

```bash
aws ec2 stop-instances --instance-ids <instance-id>
```

After stopping the instance, I terminated it:

```bash
aws ec2 terminate-instances --instance-ids <instance-id>
```

### Lesson Learned

This task reinforced the difference between **stopping** and **terminating** an EC2 instance.

* **Stop:** Powers off the instance while preserving it for later use.
* **Terminate:** Permanently deletes the instance.

It also reinforced the importance of identifying the correct instance before performing destructive operations.

---

## 3. Personal Task

### KodeKloud Engineer Docker L1

I started working on the **KodeKloud Engineer Docker L1** tasks.

I completed **2 Docker L1 tasks**.

---

## Key Takeaways

* Troubleshot Apache across multiple servers.
* Used logs to identify a port conflict.
* Resolved a service issue by stopping the conflicting process and restarting Apache.
* Practiced the EC2 instance deletion workflow using the AWS CLI.
* Reinforced the difference between stopping and terminating an EC2 instance.
* Started building practical Docker experience through KodeKloud Engineer Docker L1.

### Day Status

| Area                     | Status               |
| ------------------------ | -------------------- |
| 100 Days of DevOps       | 🟢 Completed         |
| 100 Days of Cloud — AWS  | 🟢 Completed         |
| Personal Docker Practice | 🟢 2 Tasks Completed |

> **Major realization:** Troubleshooting multiple servers requires a systematic approach — identify the affected server, check the evidence, find the underlying cause, fix it, and verify that the service is working again.

**Overall: 🟢 Day 14/100 — Completed**

```
```
