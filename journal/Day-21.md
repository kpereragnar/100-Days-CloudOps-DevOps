```markdown
# CloudOps / DevOps Journal

## Day 21 — 3 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Create a Bare Git Repository

I was tasked with creating a bare git repository.

### What I Did

```bash
ssh natasha@ststor01
sudo su -
git init --bare /opt/official.git
```

Output:

```
Initialized empty Git repository in /opt/official.git/
```

**How I verified it was actually bare:**

```bash
cd /opt/official.git
git rev-parse --is-bare-repository
# true
```

And checked the structure — no `.git/` subfolder inside, just the metadata files directly:

```bash
ls /opt/official.git
# HEAD  config  description  hooks  info  objects  refs
```

### What I Learned

**A bare repo has no working tree** — the metadata lives directly in the directory, not inside a `.git/` subfolder. That's the whole point: it's meant to be a **server-side remote** that developers push to, not a place where you edit files directly.

Compare:

| | Bare (`git init --bare repo.git`) | Non-bare (`git init repo`) |
|---|---|---|
| Structure | `repo.git/HEAD` | `repo/.git/HEAD` |
| Working tree | ❌ None | ✅ Yes |
| Can commit locally | ❌ No | ✅ Yes |
| Purpose | Server-side remote | Developer clone |

The command itself was one line, but understanding **why** you'd use a bare repo mattered more — it's the difference between "a folder with code" and "a remote that others push to."

### Lesson Learned

Bare repos are the standard for **server-side Git hosting** (GitHub, GitLab, internal Git servers all use bare repos under the hood). If you're setting up an internal remote, you use `git init --bare`. If you're setting up a working directory, you use `git init` (no `--bare`).

The `.git` suffix on the directory name is just a naming **convention** — it doesn't make the repo bare. `--bare` does.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create an EIP and Attach It to an EC2 Instance

I was tasked with creating an Elastic IP and associating it with a new EC2 instance.

### What I Did

**Step 1 — Created a key pair:**

```bash
aws ec2 create-key-pair --key-name my-key \
  --query "KeyMaterial" --output text > my-key.pem

chmod 400 my-key.pem
```

**Step 2 — Launched an EC2 instance:**

```bash
aws ec2 run-instances \
  --image-id <ami-id> \
  --instance-type t3.micro \
  --key-name my-key \
  --security-group-ids <sg-id> \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=<name>}]'
```

**Step 3 — Allocated an Elastic IP:**

```bash
aws ec2 allocate-address --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=<eip-name>}]'
```

**Step 4 — Associated the EIP with the instance:**

```bash
aws ec2 associate-address \
  --instance-id <instance-id> \
  --allocation-id <alloc-id>
```

### What I Learned

**The EIP workflow has 3 distinct steps** that are easy to mix up:

```
allocate-address  →  creates the EIP in your account
associate-address →  attaches it to an instance/ENI
release-address   →  returns it to AWS (stops the charge)
```

**`associate` ≠ `attach`.** EC2 uses "attach" for volumes and network interfaces, but EIPs use "**associate**." There is no `attach-address` command. This tripped me up before.

**EIPs are region-scoped, not AZ-scoped.** Unlike EBS volumes (which must match the instance's AZ), an EIP can be associated with any instance in the same region.

**Cost note:** EIPs are billed **even when idle** — an allocated but unassociated EIP still costs ~$3.60/month. Always release when done.

### Verification

```bash
aws ec2 describe-addresses --allocation-ids <alloc-id> \
  --query "Addresses[0].{IP:PublicIp,Instance:InstanceId,Assoc:AssociationId}" \
  --output table
```

The `Instance` field should show the instance ID — confirming the EIP is attached.

---

## 3. Personal Task

**Could not complete any personal task today due to a power outage.**

The journal entry is being written the following day (4 October) once power was restored.

**Lesson (in its own way):** Learning plans don't survive contact with reality. Power outages, internet drops, family emergencies — life happens. What matters isn't doing the task every single day; it's **not using one missed day as an excuse to stop entirely.** Continue tomorrow. Don't restart, don't try to catch up — just continue.

---

## Key Takeaways

- 🏢 **Bare repos are for server-side remotes** — no working tree, metadata at the top level, `--bare` is what makes it bare, not the `.git` suffix.
- 📋 **EIP workflow is three steps:** allocate → associate → release.
- 🔗 **"Associate" is the EIP verb**, not "attach." Different AWS resources use different verbs.
- 💰 **Idle EIPs cost money** — always release when done.
- 🔑 **Key pairs + run-instances + allocate + associate** — the four-command flow for a public-facing EC2 instance.
- 🛌 **Missed days happen.** A power outage isn't a streak-breaker — quitting is. Continue from where you left off tomorrow.

---

## Day Status

| Area                       | Status              |
| -------------------------- | ------------------- |
| 100 Days of DevOps         | 🟢 Completed        |
| 100 Days of Cloud — AWS    | 🟢 Completed        |
| Personal Task              | ⚪ Skipped (power)  |

### Overall: 🟢 Day 21/100 — Completed

> **Major realization:** Today was two "small" tasks — one bare repo, one EIP attach — but both taught the same underlying lesson: **each AWS/Git operation has its own vocabulary and its own lifecycle.** `init --bare` is different from `init`. `associate-address` is different from `attach-volume`. Learn the verb, understand the lifecycle (allocate → associate → release), and the commands stop feeling arbitrary. And when life interrupts the streak, resume — don't restart.
```
