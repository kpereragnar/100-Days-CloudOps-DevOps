```markdown
# CloudOps / DevOps Journal

## Day 26 — 8 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Add a New Git Remote and Push Both Branches

I was tasked with:

1. Add a new remote called `dev_blog` in `/usr/src/kodekloudrepos/blog`, pointing to `/opt/xfusioncorp_blog.git`
2. Copy `/tmp/index.html` into the repo, add and commit it to `master`
3. Push `master` to the new remote

### What I Did

**Step 1 — Added the new remote:**

```bash
cd /usr/src/kodekloudrepos/blog
git remote add dev_blog /opt/xfusioncorp_blog.git
git remote -v
```

**Step 2 — Copied the file and committed:**

```bash
cp /tmp/index.html .
git add index.html
git commit -m "Add index.html"
```

**Step 3 — Pushed to the new remote:**

```bash
git push dev_blog master
```

### Key Learning

**The word "origin" in the task is misleading.**

The task said *"push master branch to this new remote origin."* But there's already a remote literally named `origin` (the original source). The task means push to **the new remote you just added** — `dev_blog`.

| What you'd assume | What's correct |
|---|---|
| `git push origin master` | ❌ Pushes to the OLD remote |
| `git push dev_blog master` | ✅ Pushes to the NEW remote |

**Read the task literally.** "Origin" is being used loosely to mean "the new remote destination" — not the remote named `origin`.

Also reinforced: `git remote -v` shows what remotes exist. Always verify before pushing if you're not sure which remote is which.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Launch EC2 with User-Data Script (Nginx) + HTTP Security Group

I was tasked with:

1. Launch an EC2 instance named `datacenter-ec2`
2. Use any available Ubuntu AMI
3. Configure a user-data script that installs Nginx and starts the service on launch
4. Ensure the security group allows HTTP traffic on port 80 from the internet

### What I Did

**Step 1 — Found the latest Ubuntu AMI:**

```bash
AMI_ID=$(aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

echo "AMI: $AMI_ID"
```

**Step 2 — Created a security group allowing HTTP:**

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

SG_ID=$(aws ec2 create-security-group \
  --group-name datacenter-sg \
  --description "Allow HTTP from internet" \
  --vpc-id "$VPC_ID" \
  --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

**Step 3 — Wrote the user-data script:**

```bash
cat > /tmp/userdata.sh <<'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
```

**Step 4 — Launched the instance with the script:**

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --security-group-ids "$SG_ID" \
  --user-data file:///tmp/userdata.sh \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=datacenter-ec2}]' \
  --query "Instances[0].InstanceId" --output text)
```

**Step 5 — Waited and tested:**

```bash
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

sleep 60
curl -I "http://$IP"
```

Result: `HTTP/1.1 200 OK` with `Server: nginx/...` — the user-data script ran successfully.

### Key Learning

**User-data runs once on first boot.** It's cloud-init — the script executes automatically when the instance starts for the first time. You don't have to SSH in and run it manually.

**The package manager matters.**

| OS family | Install command |
|---|---|
| Ubuntu / Debian | `apt-get install -y nginx` |
| RHEL / CentOS / Amazon Linux | `yum install -y nginx` |

Using `yum` on Ubuntu fails silently — cloud-init logs show the error, but you won't see it unless you check `/var/log/cloud-init-output.log` on the instance.

**`--user-data file://<path>`** — the `file://` prefix is required. Without it, AWS treats the argument as literal text instead of a file path.

**Security group and user-data work together.** The user-data installs nginx (which listens on port 80). The security group opens port 80 to the internet. Without one or the other, the site isn't reachable.

**AMI lookup becomes muscle memory.** The pattern is:

```bash
aws ec2 describe-images --owners <owner-id> \
  --filters "Name=name,Values=<pattern>" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text
```

For Ubuntu, the owner is `099720109477`. For Amazon Linux, it's `amazon`. For Debian, it's `136693071363`.

---

## 3. Personal Task — Ansible Passwordless SSH Setup

### Task: Configure Passwordless SSH from thor to Managed Nodes

The Nautilus DevOps team needed passwordless SSH from `thor@jump-host` to `stapp03` (as user `banner`) before running Ansible playbooks.

### What I Did

**Step 1 — Generated an SSH key for thor (no passphrase):**

```bash
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
```

**Step 2 — Copied the public key to stapp03:**

```bash
ssh-copy-id banner@stapp03
```

Password entered once: `BigGr33n`

**Step 3 — Verified passwordless access:**

```bash
ssh banner@stapp03 "hostname"
# stapp03 — no password prompt
```

**Step 4 — Updated the inventory to use key auth:**

```ini
[app_servers]
stapp01 ansible_host=stapp01 ansible_user=tony
stapp02 ansible_host=stapp02 ansible_user=steve
stapp03 ansible_host=stapp03 ansible_user=banner
```

Removed all `ansible_ssh_pass=...` lines.

**Step 5 — Tested with Ansible ping:**

```bash
ansible stapp03 -i inventory -m ping
```

Result:

```
stapp03 | SUCCESS => {
    "ansible_facts": {...},
    "changed": false,
    "ping": "pong"
}
```

### Issues I Faced and How I Fixed Them

**Issue — `sshpass` error with host key checking enabled**

When I first tried `ansible stapp03 -i inventory -m ping`, I got:

```
Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.
```

**Root cause:** The inventory was using **password authentication** (`ansible_ssh_pass`). But SSH hadn't seen `stapp03`'s host key before, so it wanted to verify the fingerprint first. Ansible can't answer that interactive prompt — the connection just fails.

**The proper fix:** Set up **key-based authentication** instead of password auth. That's what "passwordless SSH" actually means.

**The shortcut (NOT what the task wanted):** Add `host_key_checking = False` to `ansible.cfg`. This would silence the error — but it's still password authentication, not passwordless. The task explicitly asks for passwordless, so keys are the correct answer.

**The workflow:**

1. `ssh-keygen -N ""` — generate keypair without passphrase
2. `ssh-copy-id banner@stapp03` — install the public key on the target
3. Remove `ansible_ssh_pass` from inventory
4. Add `ansible_user=<user>` so Ansible knows who to SSH as
5. Ping to verify

### Key Learning

> **Passwordless SSH = keys, not "disabled password prompts."**

There's a subtle but important distinction:

| Approach | What it does |
|---|---|
| Set `host_key_checking = False` | Silences the warning — still uses passwords |
| Set up SSH keys with `ssh-copy-id` | True passwordless authentication |

The first is a **workaround**. The second is the **actual solution** — and what Ansible automation is designed around.

**How passwordless SSH works:**

1. `thor` generates a keypair: private key stays on jump host, public key is shared
2. Public key goes into `~/.ssh/authorized_keys` of the target user (`banner@stapp03`)
3. When `thor` connects, SSH asks the target to send an encrypted challenge
4. `thor` decrypts it with the private key — proving possession without ever sending the key
5. Authentication succeeds, no password typed

**The private key never leaves the controller.** That's the security model.

**`ssh-copy-id` handles all the plumbing:**

- Creates `~/.ssh/` on the target if missing
- Sets correct permissions (700 for `.ssh`, 600 for `authorized_keys`)
- Appends the public key idempotently (no duplicates on re-run)

Without `ssh-copy-id`, you'd have to do all of that manually — and the permissions are easy to get wrong, which causes silent SSH failures.

---

## Key Takeaways

- 🌿 **"Origin" in Git tasks can be misleading.** It might mean the remote literally named `origin`, or just "the destination". Read carefully and verify with `git remote -v`.
- ☁️ **User-data runs once on first boot.** Use it to bootstrap packages and services without SSHing in.
- 🐧 **Package manager must match the OS.** `apt-get` for Ubuntu, `yum` for RHEL family. Wrong choice fails silently in cloud-init.
- 🔑 **Passwordless SSH = keys, not disabled prompts.** `ssh-copy-id` is the correct tool.
- 🎯 **The public key goes to the target, the private key stays on the source.** That's the security model.
- 📖 **`ansible_ssh_pass` in inventory is a fallback**, not a long-term solution. Once keys are set up, remove it.
- ✅ **Verify with a single command.** `ssh banner@stapp03 "hostname"` before running Ansible. If that works, Ansible will too.

---

## Day Status

| Area                            | Status       |
| ------------------------------- | ------------ |
| 100 Days DevOps                 | 🟢 Completed |
| 100 Days Cloud — AWS            | 🟢 Completed |
| Personal Ansible Task           | 🟢 Completed |
| Git (remote + push)             | 🟢 Reinforced |
| AWS (EC2 + user-data + SG)      | 🟢 Completed |
| Ansible (passwordless SSH)      | 🟢 Completed |

**Overall: 🟢 Day 26/100 — Completed**

> **Major realization:** Both the Git and Ansible tasks came down to the same lesson — **the tools have specific expectations, and shortcuts don't work.** `git push origin master` looks fine but pushes to the wrong remote. `ansible_ssh_pass` in the inventory looks like it should work but fails on host key checking. The right path in both cases was to **read the task carefully, verify with the right diagnostic command, and use the tool the way it was designed to be used.** Passwords work in a pinch. Keys work forever.
```
