```markdown
# CloudOps / DevOps Journal

## Day 22 — 4 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Clone a Git Repository

I was tasked with cloning a Git repository.

This was straightforward because I had already completed the **Git L1 and L2** tasks during the previous days of the challenge.

The task reinforced the Git workflow and gave me another opportunity to apply what I had already learned rather than encountering Git as something completely new.

### Key Learning

> The progression through Git L1 and L2 is already paying off. Tasks that would have previously required research are becoming routine.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Securely Accessible EC2 Instance

The Nautilus DevOps team needed a new EC2 instance that could be accessed securely from the landing host **`aws-client`**.

**Requirements included:**

- ✅ Create a **t2.micro** EC2 instance
- ✅ Name it **`datacenter-ec2`**
- ✅ Create an SSH key named **`id_rsa`** on the `aws-client` host under `/root/.ssh/`
- ✅ Configure the key for passwordless SSH access
- ✅ Add the corresponding public key to the EC2 instance's **root user's** `authorized_keys`
- ✅ Allow SSH access from the landing host

> ⚠️ **This was easily the most stressful Cloud task I've encountered since starting the challenge.**

---

### 🔑 Creating the SSH Key

I created the key pair using the AWS CLI and retrieved the private key material:

```bash
aws ec2 create-key-pair \
  --key-name id_rsa \
  --key-type rsa \
  --query "KeyMaterial" \
  --output text > /root/.ssh/id_rsa
```

I then created the EC2 instance.

One of the first challenges was obtaining the correct **AMI ID**. Finding the appropriate AMI and using the correct image ID added another layer of complexity.

---

### 🚨 The SSH Problem

After the instance was created, I attempted to connect:

```bash
ssh -i /root/.ssh/id_rsa ubuntu@<EC2-IP>
```

Instead of connecting, SSH returned:

```text
Connection refused
```

I spent roughly **an hour** troubleshooting the issue.

I restarted the EC2 instance multiple times and tried different approaches, but couldn't get the connection working before the task timer expired.

So I had to start the task again.

---

### 🔄 Attempt #2 — Empty Key

During the second attempt, I recreated the key pair.

Unfortunately, I made a mistake while entering the command, resulting in the **private key saved on `aws-client` being empty**.

I had to delete the EC2 instance and key pair and start again.

---

### 🔄 Attempt #3 — The Breakthrough

On the third attempt, I created the key pair again, but this time I omitted the `--key-type` option.

That introduced another problem where the key configuration didn't match what I expected when attempting SSH.

After working through the key issue, I tried connecting again.

**Connection refused.**

> At this point, I was seriously frustrated.

Then I stopped and thought:

> *"Wait o... could it be the Security Group?"* 😭

I checked the Security Group's inbound and outbound rules.

**That's when I found the actual problem:**

> ## ❌ **Port 22 wasn't allowed for inbound SSH traffic.**

I added the appropriate SSH ingress rule and tried connecting again.

---

### 🔥 It Worked

SSH access was successful.

I then continued with the remaining requirements:

- ✅ Configure root SSH access
- ✅ Add the public key to the root user's `authorized_keys`
- ✅ Configure passwordless SSH authentication
- ✅ Verify access from `aws-client`

This was where the **Linux and DevOps knowledge** I had built during the previous days became extremely useful.

---

### 💡 Major Lesson

This task taught me something important:

> ## **When troubleshooting connectivity, don't assume the problem is with the thing you're currently looking at.**

I initially focused heavily on:

```text
SSH key → Private key → EC2 → SSH
```

But the actual problem was:

```text
     aws-client
          ↓
     SSH request
          ↓
  EC2 Security Group
          ↓
  ❌ Port 22 blocked
```

Once port 22 was allowed, the SSH connection worked.

It was a frustrating task, but it was also **one of the most valuable troubleshooting experiences I've had so far**.

---

## 3. Personal Practice — Ansible

I continued building my Ansible skills by completing two **Ansible L1** tasks:

### Task 1: Troubleshoot

Worked through an Ansible troubleshooting task and investigated configuration issues rather than simply recreating the environment.

### Task 2: Create Ansible Playbook

Created an Ansible playbook to automate the required configuration.

### Additional Practice

I also worked on:

**Create Ansible Inventory for App Server Testing**

This is an important step as I'm beginning to move from manually configuring individual servers toward **automating configuration across multiple machines**.

---

## Key Takeaways

### 🔐 1. SSH Has Multiple Dependencies

Successful SSH access isn't just about having the correct private key.

The chain can involve:

```text
   Private Key
        ↓
   Public Key
        ↓
 authorized_keys
        ↓
 SSH Configuration
        ↓
 EC2 Security Group
        ↓
     Port 22
        ↓
    SSH Service
```

> **Any one of these can prevent access.**

---

### ☁️ 2. AWS Troubleshooting Requires Looking Beyond the Instance

An EC2 instance can be perfectly healthy while still being inaccessible because of **external networking controls** such as Security Groups.

---

### 🧠 3. Don't Troubleshoot Only What You Assume Is Broken

I spent a significant amount of time focusing on the SSH key because the error appeared during SSH authentication.

> **The actual problem was the Security Group.**

---

### ⚙️ 4. Previous DevOps Knowledge Is Starting to Compound

The Linux and DevOps tasks I've completed over the past three weeks directly helped me finish the final part of this challenge.

> **Knowledge from previous tasks is no longer isolated. It's starting to connect.**

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps | 🟢 Completed |
| 100 Days Cloud — AWS | 🟢 Completed |
| Personal Ansible Practice | 🟢 Completed |
| AWS EC2 | 🟢 |
| SSH | 🟢 |
| AWS Security Groups | 🟢 |
| Ansible | 🟢 |

**Overall: 🟢 Day 22/100 — Completed**

> **Major realization:** Sometimes the hardest part of infrastructure isn't creating the resource — it's figuring out why something that *should* work doesn't. Today was frustrating, but troubleshooting that problem from multiple angles taught me more than a task that worked perfectly on the first attempt ever could.
```



