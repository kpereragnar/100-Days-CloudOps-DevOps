# CloudOps / DevOps Journal

## Day 27 — 9 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Revert the Latest Commit in the `ecommerce` Repository

I was tasked with:

1. In `/usr/src/kodekloudrepos/ecommerce`, revert the latest commit (`HEAD`) to the previous commit.
2. Use the commit message `revert ecommerce` (all lowercase) for the new revert commit.

### What I Did

**Step 1 — Checked the latest commits:**

```bash
cd /usr/src/kodekloudrepos/ecommerce
git log --oneline -3
```

**Step 2 — Reverted HEAD without auto-committing:**

```bash
git revert --no-commit HEAD
```

**Step 3 — Created the revert commit with the exact message:**

```bash
git commit -m "revert ecommerce"
```

**Step 4 — Verified:**

```bash
git log --oneline -3
```

### Key Learning

**`git revert` creates a new commit that undoes a previous commit. It does not erase history.**

This is different from `git reset`, which moves the branch pointer and can rewrite history. The task explicitly asked for a revert commit, so `git revert` was the correct tool.

**Exact commit message matters.**  
The message had to be exactly:

```text
revert ecommerce
```

All lowercase, no capitalisation, no extra words.

**No issues faced.**  
I had already completed Git L1 and L2, so the workflow was familiar. This task reinforced hands-on practice with reverting and commit messages.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Public VPC, Subnet, and EC2 Instance with SSH Access

I was tasked with:

1. Create a public VPC named `nautilus-pub-vpc`
2. Create a subnet named `nautilus-pub-subnet` under the same VPC
3. Ensure public IP is auto-assigned to resources under this subnet
4. Create an EC2 instance named `nautilus-pub-ec2` with instance type `t2.micro`
5. Make sure SSH port 22 is open and accessible over the internet

### What I Did

**First attempt — incomplete:**

I created:

- VPC
- Subnet
- Security Group
- EC2 instance

But I did **not** configure:

- Internet Gateway
- Route table
- Route to the Internet Gateway
- Route table association with the subnet
- Auto-assign public IP on the subnet

Result: the instance was not reachable from the internet. SSH would time out.

**Second attempt — correct methodology:**

I learned that a public VPC is not a single resource. It is a **chain** of connected resources:

```text
VPC
 └── Subnet
      ├── Auto-assign public IPv4: enabled
      ├── Route table associated
      │    └── Route: 0.0.0.0/0 → Internet Gateway
      └── Internet Gateway attached to VPC
```

Then:

```text
Security Group → allows inbound SSH 22
EC2 instance → launched in that subnet
```

**Correct sequence:**

```bash
# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value=nautilus-pub-vpc

# 2. Create subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources "$SUBNET_ID" --tags Key=Name,Value=nautilus-pub-subnet

# 3. Enable auto-assign public IP on subnet
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch

# 4. Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# 5. Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

# 6. Create route table
RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)

# 7. Add route to IGW
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

# 8. Associate route table with subnet
aws ec2 associate-route-table --subnet-id "$SUBNET_ID" --route-table-id "$RT_ID"

# 9. Create security group and allow SSH
SG_ID=$(aws ec2 create-security-group --group-name nautilus-pub-sg --description "Allow SSH" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0

# 10. Launch EC2 instance
AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nautilus-pub-ec2}]' \
  --query 'Instances[0].InstanceId' --output text)
```

### Key Learning

> **“Public” is a path, not a property.**

A subnet is public only if:

1. It is associated with a route table that has a route to an Internet Gateway.
2. The Internet Gateway is attached to the VPC.
3. The subnet has auto-assign public IPv4 enabled (or the instance gets an Elastic IP).

**Security groups do not make a subnet public.**  
They only control what traffic is allowed. You can open port 22 to the world, but without a route to the internet, nobody can reach the instance.

**Most commonly forgotten steps:**

| Step | Why people forget it |
|---|---|
| Attach IGW to VPC | They create the IGW but don’t attach it |
| Create route `0.0.0.0/0 → IGW` | They create the route table but no route |
| Associate route table with subnet | They create the route table but leave it unassociated |
| Enable auto-assign public IP on subnet | They launch the instance and wonder why it has no public IP |

---

## 3. Personal Task — Ansible L2

### Task: Two Ansible Playbooks

**Task 1 — Unzip archive and set ownership/permissions:**

- Unzip `/usr/src/finance/xfusion.zip` to `/opt/finance/` on all app servers.
- Set user and group owner to the respective sudo user (`tony`, `steve`, `banner`).
- Set permissions to `0644`.

**Task 2 — Install and configure httpd:**

- Install `httpd` on all app servers.
- Ensure the service is running and enabled.
- Use `blockinfile` to add content to `/var/www/html/index.html`.
- Set owner/group to `apache` and permissions to `0777`.
- Do not use custom or empty markers.

### What I Did

**Task 1 playbook:**

```yaml
---
- name: Unzip File to /opt/finance on all app servers
  hosts: all
  become_user: root
  become: yes
  tasks:
     - name: Ensure Existence and Writablility to Dest Directory (/opt/finance/) on all app servers
       file:
          path: /opt/finance/
          state: directory
          mode: '0755'

     - name: Unzip and Copy Files to all app servers
       unarchive:
          src: /usr/src/finance/xfusion.zip
          dest: /opt/finance/
          owner: '{{ansible_user}}'
          group: '{{ansible_user}}'
          mode: '0644'
```

**Task 2 playbook:**

```yaml
---
- name: Setup httpd Web Servers on all App Servers
  hosts: all
  become_user: root
  become: yes
  tasks:
     - name: Installation of httpd on all app servers
       yum:
         name: httpd
         state: present

     - name: Start httpd
       service:
         name: httpd
         state: started
         enabled: yes 

     - name: Add content to index.html and set permissions
       blockinfile:
         path: /var/www/html/index.html
         create: yes
         owner: apache
         group: apache
         mode: '0777'
         block: |
           Welcome to XfusionCorp!

           This is  Nautilus sample file, created using Ansible!

           Please do not modify this file manually!
```

Both playbooks ran successfully with:

```bash
ansible-playbook -i inventory playbook.yml
```

### Key Learning

**Ansible modules have specific responsibilities.**  
`unarchive` extracts archives. It also supports setting `owner`, `group`, and `mode` directly, which made the first task straightforward.

**Exact content matters.**  
The `blockinfile` content had to match the task exactly — including blank lines and double spaces. Small differences can fail validation.

**Default markers are required when custom markers are prohibited.**  
I used the default markers by not specifying `marker`.

**`become_user: root` is redundant** when `become: yes` is already set, because `become` defaults to root.

**This completed Ansible L2.**

---

## Key Takeaways

- 🌿 **`git revert` creates a new commit that undoes a previous commit.** It does not erase history. Exact commit message matters.
- ☁️ **A public VPC is a chain:** VPC → Subnet → Auto-assign Public IP → IGW attached → Route Table → Route 0.0.0.0/0 → IGW → Associate Route Table with Subnet.
- 🔒 **Security groups control traffic, not routing.** Opening port 22 does not make a subnet public.
- 🧩 **Ansible `unarchive` can set ownership and permissions directly.** No separate `file` task needed for simple cases.
- 📝 **Exact content in `blockinfile` must match the task** — blank lines and spacing included.
- 🎯 **Ansible L2 completed** with two playbooks: unzip with ownership/permissions, and httpd installation with sample page.

---

## Day Status

| Area                            | Status       |
| ------------------------------- | ------------ |
| 100 Days DevOps — Git revert    | 🟢 Completed |
| 100 Days Cloud — Public VPC     | 🟢 Completed |
| Personal — Ansible L2 Task 1    | 🟢 Completed |
| Personal — Ansible L2 Task 2    | 🟢 Completed |
| Git (revert)                    | 🟢 Reinforced |
| AWS (public VPC methodology)    | 🟢 Learned   |
| Ansible (unarchive + blockinfile) | 🟢 Completed |
| **Ansible L2**                  | 🟢 Completed |

**Overall: 🟢 Day 27/100 — Completed**

> **Major realization:** A public VPC is not a single resource — it’s a connected path. And Ansible modules each have a specific job: `unarchive` extracts and can set ownership, `blockinfile` manages file content with exact precision. Understanding what each tool actually does prevents silent failures and wasted debugging time.
