# CloudOps / DevOps Journal

## Day 29 — 11 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Manage a Git Pull Request (Max's Fox and Grapes Story)

I was tasked with:

1. SSH into the storage server as `max`
2. Inspect the cloned repository and confirm Sarah's story and commit history
3. Create a Pull Request to merge Max's `story/fox-and-grapes` branch into `master`
4. Assign `tom` as a reviewer
5. Log in as `tom` and approve + merge the PR

### What I Did

**Step 1 — SSH into the storage server:**

```bash
ssh max@ststor01
# Password: Max_pass123
```

**Step 2 — Inspected the repository:**

```bash
cd ~
ls
cd <repo-name>

git log --oneline --decorate --all
git log --pretty=full
```

Confirmed Sarah's story and the commit history. Verified author info and commit messages.

**Step 3 — Created the Pull Request in Gitea UI:**

- Clicked the **Gitea** button on the top bar
- Logged in as `max` / `Max_pass123`
- Opened the repository
- Clicked **Pull Requests** → **New Pull Request**
- Source branch: `story/fox-and-grapes`
- Destination branch: `master`
- PR title: `Added fox-and-grapes story`
- Clicked **Create Pull Request**

**Step 4 — Added `tom` as reviewer:**

- On the PR page, clicked **Reviewers** in the right sidebar
- Selected `tom`

**Step 5 — Logged out and logged in as `tom`:**

- Logged out of Gitea
- Logged in as `tom` / `Tom_pass123`

**Step 6 — Approved and merged:**

- Opened the PR titled `Added fox-and-grapes story`
- Clicked **Approve**
- Clicked **Merge Pull Request** → **Confirm Merge**

The story was merged into `master`.

### Key Learning

**Pull Requests are the standard workflow for controlled merges.** No one pushes directly to `master` — changes go through a branch, then a PR, then review, then merge.

**The reviewer step is not optional in real teams.** Assigning `tom` before merging simulates the code review process. In production, this is enforced by branch protection rules that block direct pushes to `master`.

**Why this matters for DevOps:**

| Concept | Real-world application |
|---|---|
| Feature branch | Every change starts in a branch |
| Pull Request | Code review gate before merge |
| Reviewer assignment | Peer review for quality |
| Approval | Sign-off before production |
| Merge | Controlled integration into `main` |

**This is the same workflow used at every serious tech company.** GitHub, GitLab, Bitbucket — the terminology differs, but the process is identical.

**No major issues.** The Gitea UI is intuitive. The key was following the task's exact branch names, PR title, and reviewer.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: VPC Peering and Secure Communication Between Two VPCs

I was tasked with:

1. Create a VPC Peering connection between the Default VPC and the private `nautilus-private-vpc`
2. Configure route tables on both sides
3. Update security groups to allow ICMP
4. Add the aws-client's public key to the public EC2 instance
5. SSH into the public instance and ping the private instance

### What I Did

**Step 1 — Gathered existing resources:**

```bash
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

PRIVATE_VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=nautilus-private-vpc" \
  --query "Vpcs[0].VpcId" --output text)
```

**Step 2 — Created and accepted the peering connection:**

```bash
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
  --vpc-id "$DEFAULT_VPC_ID" \
  --peer-vpc-id "$PRIVATE_VPC_ID" \
  --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=nautilus-vpc-peering}]' \
  --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text)

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$PEERING_ID"
```

**Step 3 — Added routes on both sides:**

```bash
# Default VPC → Private CIDR
aws ec2 create-route \
  --route-table-id "$DEFAULT_RT_ID" \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id "$PEERING_ID"

# Private VPC → Default CIDR
aws ec2 create-route \
  --route-table-id "$PRIVATE_RT_ID" \
  --destination-cidr-block 172.31.0.0/16 \
  --vpc-peering-connection-id "$PEERING_ID"
```

**Step 4 — Allowed ICMP on the private instance's security group:**

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$PRIVATE_SG_ID" \
  --ip-permissions 'IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=172.31.0.0/16,Description="ICMP from Default VPC"}]'
```

**Step 5 — Fixed SSH access to the public instance:**

The public SG only had a self-referencing rule (`-1` protocol from itself). No SSH from the internet was allowed.

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$PUBLIC_SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
```

Then pushed the aws-client's public key to the instance:

```bash
aws ec2-instance-connect send-ssh-public-key \
  --instance-id "$INSTANCE_ID" \
  --instance-os-user ec2-user \
  --ssh-public-key file:///root/.ssh/id_rsa.pub

ssh -i /root/.ssh/id_rsa ec2-user@$PUBLIC_IP
```

Inside the instance, added the key permanently to `authorized_keys`:

```bash
echo "ssh-rsa AAAAB3... root@aws-client" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
restorecon -Rv ~/.ssh
```

**Step 6 — Tested connectivity:**

```bash
ssh -i /root/.ssh/id_rsa ec2-user@$PUBLIC_IP
ping -c 4 <private-ip>
```

Ping succeeded — the peering connection was working end-to-end.

### Issues I Faced and How I Fixed Them

**Issue 1 — Route table query returned `None`**

I used:

```bash
--filters "Name=association.subnet-id,Values=$PRIVATE_SUBNET_ID"
```

This returned `None` because the private subnet wasn't **explicitly** associated with a route table. It was using the VPC's **main** route table instead.

**Fix:** Query the main route table directly:

```bash
--filters "Name=vpc-id,Values=$PRIVATE_VPC_ID" \
          "Name=association.main,Values=true"
```

**Issue 2 — SSH to the public instance timed out**

Verbose SSH (`ssh -vvv`) showed:

```
connect to address 13.217.13.224 port 22: Connection timed out
```

This is a **network-level failure**, not an SSH auth failure. No output, no error, just silence.

**Root cause:** The public instance's security group only had a self-referencing rule. No inbound SSH from the internet was allowed.

**Fix:** Added TCP 22 from `0.0.0.0/0` to the public SG.

**Issue 3 — SSH connected but rejected the key**

After fixing the SG, SSH connected but returned:

```
ec2-user@13.217.13.224: Permission denied (publickey)
```

**Root cause:** The aws-client's public key wasn't in `ec2-user`'s `authorized_keys` on the public instance.

**Issue 4 — EC2 Instance Connect wasn't available**

The AWS console didn't show the EC2 Instance Connect option in this lab environment.

**Fix:** Used the AWS CLI equivalent:

```bash
aws ec2-instance-connect send-ssh-public-key \
  --instance-id "$INSTANCE_ID" \
  --instance-os-user ec2-user \
  --ssh-public-key file:///root/.ssh/id_rsa.pub
```

This pushed the key temporarily (60 seconds), giving enough time to SSH in and add it permanently.

### Key Learning

> **“Public” is a path, not a property.**

A subnet is public only if:

1. It has a route table with a route to an Internet Gateway
2. The IGW is attached to the VPC
3. Auto-assign public IP is enabled (or the instance has an Elastic IP)

**VPC Peering is a chain of dependencies:**

| Layer | Required on both sides |
|---|---|
| Peering connection | Accepted, status `active` |
| Route table | Route to the peer VPC CIDR via the peering connection |
| Security group | Allow the specific protocol from the peer CIDR |
| NACLs | Allow the traffic (default allows all) |

**Miss any one → packets silently dropped, no error, no output.**

**Security groups control traffic — not routing.** Opening port 22 doesn't make a subnet public. You also need the route.

**Debugging method that worked:**

1. `describe-instances` — confirm the instance is running with a public IP
2. `ssh -vvv` — see exactly where the connection fails
3. `describe-security-groups` — check what traffic is allowed
4. `describe-route-tables` — check the path to the internet

**The order matters:** network first, then auth. If SSH times out, it's never a key problem — it's a firewall or routing problem.

---

## 3. Personal Task — Jenkins L1 Certification Test

### Task: Complete the Jenkins Level 1 Certification Exam

After completing all Jenkins L1 tasks on KodeKloud Engineer, I took the final certification test.

**Exam details:**

| | |
|---|---|
| **Format** | Practical, web UI based |
| **Time limit** | 110 minutes |
| **Time taken** | 20 minutes |
| **Score** | 100% ✅ |

### What the exam covered

- Installing Jenkins and completing the setup wizard
- Installing plugins (Git, GitLab, Pipeline, Ant, Matrix Authorization Strategy)
- Creating folders and moving jobs into them
- Adding labels and updating executors on the built-in node
- Creating users and assigning permissions via Project-based Matrix Authorization Strategy
- Creating freestyle and pipeline jobs

### Key Learning

**Not every certification has to be hard.** After Ansible L1, Linux L1, Docker L1, and Git L1 — all terminal-based practicals — Jenkins L1 was a refreshing change. It was almost entirely **Web UI configuration**.

**Jenkins is a configuration-driven system.** Understanding the relationship between:

- Plugins (add capabilities)
- Folders (organize jobs)
- Labels (route builds)
- Permissions (control access)
- Users (team management)

…made everything else mechanical. The exam tested whether you understand the *system*, not whether you memorized commands.

**Module installed on day one, still relevant every day:**

| Concept | Learned |
|---|---|
| Plugins gate features | No Folders plugin = no folders |
| Java version matters | Jenkins needs Java 21 now (Java 17 silently fails) |
| Built-In Node ≠ Master | Same thing, different Jenkins versions |
| Matrix Authorization cascades | Granting "Job: Create" alone locks users out without "Overall: Read" |
| GUI → XML | Every UI click maps to filesystem config (JCasC later) |

**This completed Jenkins L1.**

### Badge status

- 🐧 Jenkins L1 — 100% ✅
- ⚙️ Ansible L1 — 100% ✅
- 🌿 Git L1 — 100% ✅
- 🐧 Linux L1 — 86% ✅
- 🐳 Docker L1 — 80% ✅

Next up: Jenkins L2.

---

## Key Takeaways

- 🌿 **Pull Requests are the standard workflow for controlled merges.** No one pushes directly to `master`. Branch → PR → review → approve → merge.
- ☁️ **VPC Peering is a chain, not a single resource.** Peering connection + routes on both sides + security group rules. Miss one link and nothing works.
- 🔍 **Timeouts are network issues, not auth issues.** When SSH times out with no output, check security groups and routes first — not keys.
- 🎯 **Public VPC methodology:** IGW attached + route table with IGW route + auto-assign public IP + SG allowing the traffic.
- 🧩 **Route table associations are implicit by default.** A subnet with no explicit route table association uses the VPC's main route table. Query with `association.main=true`.
- 🔑 **`aws ec2-instance-connect send-ssh-public-key` bootstraps SSH access** when the console's Instance Connect isn't available.
- 🏆 **Jenkins L1 completed with 100%.** Practical but web-UI based — a confidence boost after the heavier terminal-based L1 exams.

---

## Day Status

| Area                             | Status       |
| -------------------------------- | ------------ |
| 100 Days DevOps — Git PR         | 🟢 Completed |
| 100 Days Cloud — VPC Peering     | 🟢 Completed |
| Personal — Jenkins L1 Test       | 🟢 Completed |
| Git (PR workflow)                | 🟢 Reinforced |
| AWS (VPC Peering + routing)      | 🟢 Completed |
| Jenkins L1                       | 🟢 Completed |
| **Jenkins L1 Badge**             | 🟢 Earned    |

**Overall: 🟢 Day 29/100 — Completed**

> **Major realization:** Both the Git PR and the VPC Peering tasks came down to the same lesson — **nothing works in isolation; everything is a chain of dependencies.** A PR needs a branch, a reviewer, and an approval before merge. VPC Peering needs a connection, routes on both sides, and security group rules. The tools don't care if you understand the whole chain — they just fail silently when one link is missing. The job is to learn the chain, then debug it in order: network → routing → firewall → authentication.
