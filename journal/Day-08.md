````markdown
# CloudOps / DevOps Journal

## Day 8 — 20 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task

I was tasked with installing **Ansible 4.9.0** on the jump host server using **pip3 only**.

The installation also needed to be accessible to **all users** on the server.

### Approach

I installed Ansible using `pip3` with `sudo` so that it would be installed system-wide and accessible to users on the server.

I used:

```bash
sudo pip3 install ansible==4.9
````

### Verification

After installation, I verified that Ansible was available by checking its version:

```bash
ansible --version
```

### Lesson Learned

This task gave me more practical experience with Python package installation on Linux using `pip3`.

I also reinforced the importance of understanding the difference between installing a package for a single user and installing it system-wide.

Using `sudo` allowed the package to be installed at the system level so that other users could access the Ansible installation.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

I was tasked with enabling **EC2 Stop Protection** for an existing EC2 instance.

Stop protection prevents an instance from being accidentally stopped through the EC2 API.

### Approach

I first identified the required EC2 instance and then used the AWS CLI `modify-instance-attribute` command to configure the instance's stop protection.

The relevant option was:

```bash
--disable-api-stop
```

Example:

```bash
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --disable-api-stop
```

### Lesson Learned

This task introduced me to another EC2 protection mechanism.

I learned that AWS provides configuration options that can help prevent accidental actions against infrastructure.

I also reinforced my understanding of the `modify-instance-attribute` command and how it can be used to change EC2 instance attributes through the AWS CLI.

---

## 3. Personal Task — Linux L1 KodeKloud Practice

For my personal learning, I completed **9 Linux L1 tasks on KodeKloud**.

The tasks covered different areas of Linux administration, permissions, security, file management, scripting, and access control.

### Tasks Completed

#### 1. Temporary User Setup with Expiry

Practiced creating a Linux user with a specified account expiration date.

**Concepts:**

* User management.
* Account expiration.
* User lifecycle management.

---

#### 2. Linux User Data Transfer

Practiced transferring or copying data between Linux users.

**Concepts:**

* Linux users.
* File ownership.
* File permissions.
* Data management between user environments.

---

#### 3. Secure Root SSH Access

Worked with SSH configuration related to root access.

**Concepts:**

* SSH configuration.
* Root login security.
* Remote access hardening.

---

#### 4. Data Backup for Developer

Practiced creating backups of required developer data.

**Concepts:**

* File management.
* Backup operations.
* Data preservation.

---

#### 5. Script Execution Permissions

Practiced modifying file permissions so that scripts could be executed correctly.

**Concepts:**

* Linux permissions.
* `chmod`.
* Executable permissions.
* File ownership.

---

#### 6. File Permission Correction

Worked with correcting incorrect permissions on files.

**Concepts:**

* Linux permission model.
* Read, write, and execute permissions.
* Permission troubleshooting.

---

#### 7. String Replacement

Practiced replacing specific strings within files.

**Concepts:**

* Text processing.
* Linux command-line utilities.
* File manipulation.

---

#### 8. Secure Data Transfer

Practiced securely transferring files between systems.

**Concepts:**

* Secure file transfer.
* SSH.
* Remote Linux administration.

---

#### 9. Restrict Cron Access

Practiced controlling which users are allowed or denied access to cron.

**Concepts:**

* Cron security.
* User access control.
* Linux service restrictions.

---

# Day 8 — Key Takeaways

## DevOps Lessons

* Ansible can be installed through Python's package manager using `pip3`.
* `sudo pip3 install` can be used for system-wide package installation.
* Package accessibility depends on where and how the package is installed.
* Ansible is an important automation tool in DevOps environments.

## AWS Lessons

* EC2 instances have configurable protection mechanisms.
* Stop protection can help prevent accidental API-based stopping of an instance.
* `modify-instance-attribute` can be used to modify EC2 instance attributes.
* AWS CLI provides granular control over EC2 configuration.

## Linux Lessons

Today's personal Linux practice strengthened my understanding of:

* User management.
* Account expiration.
* File permissions.
* SSH security.
* Root access restrictions.
* Backup operations.
* Secure file transfer.
* Text manipulation.
* Cron access control.
* Linux security and administration.

---

# Day 8 Status

| Area                      | Status               |
| ------------------------- | -------------------- |
| 100 Days DevOps Challenge | ✅ Completed          |
| Ansible Installation      | 🟢 Practiced         |
| `pip3` Package Management | 🟢 Practiced         |
| System-Wide Installation  | 🟢 Practiced         |
| AWS EC2 Stop Protection   | 🟢 Practiced         |
| AWS CLI                   | 🟢 Practiced         |
| Linux User Management     | 🟢 Practiced         |
| Linux Permissions         | 🟢 Practiced         |
| SSH Security              | 🟢 Practiced         |
| Secure File Transfer      | 🟢 Practiced         |
| Cron Access Control       | 🟢 Practiced         |
| Linux L1 Tasks            | 🟢 9 Tasks Completed |

**Overall: 🟢 Day 8/100 — Completed**

> **Major realization:** Every task is adding another piece to the bigger picture. Linux administration, security, AWS infrastructure, and automation are not isolated skills — they are building blocks for becoming effective in CloudOps and DevOps.

```
```

