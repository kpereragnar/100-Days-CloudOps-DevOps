# CloudOps / DevOps Journal

## Day 30 — 12 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Reset Git Commit History

I was tasked with:

1. In `/usr/src/kodekloudrepos/apps`, reset the commit history so only two commits remain — `initial commit` and `add data.txt file`
2. Point `HEAD` and the branch back to `add data.txt file`
3. Push the changes

### What I Did

**Step 1 — Inspected the current history:**

```bash
cd /usr/src/kodekloudrepos/apps
git log --oneline
```

Output showed 12 commits, with `add data.txt file` sitting at position 11 from the top:

```
15d9cd1 Test Commit10
c58264b Test Commit9
...
5b68232 Test Commit1
da4fea7 add data.txt file    ← target
8c64def initial commit
```

**Step 2 — Reset hard to the target commit:**

```bash
git reset --hard da4fea7
```

**Step 3 — Force pushed to the remote:**

```bash
git push origin master --force-with-lease
```

**Step 4 — Verified:**

```bash
git log --oneline
```

Output:

```
da4fea7 (HEAD -> master) add data.txt file
8c64def initial commit
```

Exactly two commits. Done.

### Key Learning

**`--hard` is what makes it a cleanup, not just a rewind.**

| Flag | Effect |
|---|---|
| `--soft` | Keeps test commits' changes **staged** |
| `--mixed` | Keeps them **unstaged** |
| `--hard` | **Discards** them entirely |

The task said "clean this repository along with the commit history/work tree" — that's `--hard`. Anything else leaves the file changes behind.

**Force push is required after a history rewrite.**

Once you reset the local branch, it diverges from the remote. A normal push is rejected:

```
! [rejected] master -> master (non-fast-forward)
```

`--force-with-lease` overwrites the remote but fails safely if someone else pushed since your last fetch. It's the right habit over plain `--force`.

**Had already covered this ground.** Git L1 and L2 covered reset and force push. This was hands-on reinforcement rather than new learning.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: NAT Instance for Private Subnet Internet Access

I was tasked with:

1. Create a public subnet `datacenter-pub-subnet` in the existing VPC
2. Launch a NAT instance `datacenter-nat-instance` (Amazon Linux 2023) in that subnet
3. Configure it to act as a NAT instance
4. Verify that `datacenter-test.txt` appears in the S3 bucket `datacenter-nat-41827333`

### What I Did

**Reconnaissance first:**

```bash
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=datacenter-priv-vpc" \
  --query "Vpcs[0].VpcId" --output text)

# VPC CIDR, existing subnets, existing IGW, etc.
```

**Built the public recipe:**

1. Created public subnet `datacenter-pub-subnet` (CIDR `10.1.2.0/24`)
2. Created and attached an Internet Gateway
3. Created a public route table with `0.0.0.0/0 → IGW` and associated it with the public subnet

**Built the NAT instance:**

4. Created a custom security group `datacenter-nat-sg`
5. Launched `datacenter-nat-instance` (Amazon Linux 2023, `t2.micro`) in the public subnet
6. Disabled source/destination check
7. SSH'd in and configured:
   - Installed and enabled `iptables-services`
   - Enabled IP forwarding (`net.ipv4.ip_forward=1`)
   - Added `MASQUERADE` rule on the correct interface
   - Saved iptables rules

**Routed the private subnet:**

8. Added `0.0.0.0/0 → NAT instance` to the private subnet's route table

### Issues I Faced and How I Fixed Them

This task was **frustrating**. Four separate failures, each one silent. Here's the full debugging path.

**Issue 1 — Wrong interface name in iptables**

I added the MASQUERADE rule with `-o eth0`, following every tutorial I'd seen. But Amazon Linux 2023 uses predictable network interface names — the actual interface was `enX0`.

The rule was silently matching nothing. Packets arrived at the NAT instance but were never rewritten.

**Fix:** Deleted the wrong rule and added the correct one:

```bash
sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
sudo /sbin/iptables -t nat -A POSTROUTING -o enX0 -j MASQUERADE
sudo service iptables save
```

**Issue 2 — FORWARD chain showed 0 packets**

Even after fixing the interface, the bucket stayed empty. Checking the NAT instance:

```bash
sudo iptables -L FORWARD -n -v
```

Output:

```
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
```

Zero packets. This was the key clue — **no forwarded traffic was reaching the NAT instance at all**. Everything on the NAT side was correct. The problem had to be upstream.

**Issue 3 — Checked NACLs (they were fine)**

```bash
aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=$PRIV_SUBNET_ID"
```

Both private and public subnet NACLs allowed all traffic. Ruled out.

**Issue 4 — The actual root cause: wrong route table**

I had added the `0.0.0.0/0 → NAT instance` route to the **main** route table (`rtb-0e583a0e21e8a98f2`) using `association.main=true`.

But when I dumped every route table in the VPC with their associations, I found:

```json
{
    "RT": "rtb-09558183ced4f92ed",
    "Main": false,
    "SubnetAssoc": "subnet-0300fec30e60614f1",   ← the private subnet
    "Routes": [
        { "Dest": "10.1.0.0/16", "Gw": "local" }  ← no 0.0.0.0/0
    ]
}
```

The private subnet was **explicitly associated with a custom route table** (`rtb-09558183ced4f92ed`), not the main one. The NAT route I added was in a route table with **no subnet associations** — completely unused.

**Fix:** Added the route to the correct table:

```bash
aws ec2 create-route \
  --route-table-id rtb-09558183ced4f92ed \
  --destination-cidr-block 0.0.0.0/0 \
  --instance-id "$NAT_INSTANCE_ID"
```

Within a minute, `datacenter-test.txt` appeared in the S3 bucket.

### Key Learning

> **The main route table is not always the route table in use.**

AWS gives every VPC a main route table. But subnets can be explicitly associated with custom route tables. When that happens, the main route table is irrelevant for that subnet.

**The ground truth query:**

```bash
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID"
```

Not `association.main=true`. Not "the first route table." The one tied to the specific subnet.

**A public VPC and a working NAT instance both follow the same pattern:**

| Layer | Public subnet | Private subnet |
|---|---|---|
| Route `0.0.0.0/0` → | Internet Gateway | NAT instance |
| Everything else | Same | Same |

Two route tables, two different targets. That's the only structural difference.

**Amazon Linux 2023 gotchas:**

| Gotcha | Fix |
|---|---|
| No `eth0` — uses `enX0` or `ens5` | Check `ip -br link` before writing iptables rules |
| `iptables` not installed | `yum install iptables-services -y` |
| `iptables-services` needed to persist rules | `service iptables save` |

**Diagnostic order when "everything looks right":**

1. Is the route in the right route table? (check the **subnet association**)
2. Is source/dest check disabled on the NAT instance?
3. Does the NAT instance itself have internet access?
4. Is the MASQUERADE rule on the **correct interface**?
5. Are NACLs and security groups allowing the traffic?

The failure I hit — FORWARD showing 0 packets — points directly to a routing problem upstream of the NAT instance, not a problem on the instance itself. That single signal saved hours of fruitless iptables debugging.

### The automation payoff

After fixing it manually, I built a complete bash script that sets up everything idempotently — public subnet, IGW, route table, SG, NAT instance with user-data that auto-detects the interface, source/dest check, and the route in the **actual** private subnet route table. Every gotcha is baked in.

---

## 3. Personal Task — Terraform

### Task: Five Terraform Tasks

Today's personal work was five Terraform tasks covering the basics of resource creation.

**What was covered:**

| Task | Resource created | Key attribute |
|---|---|---|
| Key pair | `tls_private_key` + `aws_key_pair` + `local_file` | RSA algorithm, private key saved to disk |
| Security group | `aws_security_group` | Ingress rules, VPC lookup via `data` source |
| VPC | `aws_vpc` | `cidr_block` + `Name` tag |
| VPC with IPv6 | `aws_vpc` | `assign_generated_ipv6_cidr_block = true` |

### Key Learning

**Terraform syntax is a pattern, not a memorization exercise.**

Every resource follows the same shape:

```hcl
resource "<provider>_<type>" "<local_name>" {
  argument = value

  nested_block {
    argument = value
  }
}
```

Only two things change between resources: the **type** (look up in the registry) and the **required arguments** (look up in the registry).

**HCL has only four building blocks:**

| Type | Example |
|---|---|
| String | `cidr_block = "10.0.0.0/16"` |
| Number | `from_port = 80` |
| List | `cidr_blocks = ["0.0.0.0/0"]` |
| Map | `tags = { Name = "..." }` |

Every `.tf` file is these four, arranged into blocks.

**CIDR blocks must be quoted strings.** Writing `cidr_blocks = [0.0.0.0/0]` fails — Terraform tries to parse it as an expression. It must be `["0.0.0.0/0"]`.

**Missing closing quotes produce misleading errors.** When I forgot the closing `"` after `/0`, Terraform reported "Invalid multi-line string" at a line *below* the actual error. The error location is where Terraform gave up, not where the quote was forgotten. Scan upwards for unterminated strings.

**The four-command workflow never changes:**

```bash
terraform init      # download providers
terraform fmt       # format
terraform validate  # syntax check
terraform plan      # preview
terraform apply -auto-approve   # execute
```

**Variable references in the `provider.tf` file.** In the KodeKloud environment, `provider.tf` already exists and configures the region and LocalStack endpoints. `main.tf` should contain **only resources** — never a second `provider` block.

**Terraform local names use underscores, not hyphens.** The AWS-side name is set via the `Name` tag or the resource's `name` argument. The local name (e.g., `xfusion_sg`) is internal to Terraform only.

---

## Key Takeaways

- 🌿 **`git reset --hard` cleans both history and work tree.** `--soft` and `--mixed` leave changes behind. Follow with `--force-with-lease` to rewrite the remote.
- ☁️ **The main route table is not always the route table in use.** Always query `association.subnet-id` to find the actual association.
- 🔍 **FORWARD showing 0 packets means the problem is upstream.** Not the NAT instance itself — the routing to it.
- 🔧 **Amazon Linux 2023 uses `enX0`, not `eth0`.** Always check the interface name before writing iptables rules.
- 🧩 **A public subnet and a private subnet differ by exactly one route.** `0.0.0.0/0 → IGW` vs `0.0.0.0/0 → NAT instance`. Everything else is identical.
- 🛠️ **CLI-created security groups have no egress by default.** The console adds it automatically. The CLI does not.
- 📦 **Terraform is a pattern, not a memorization exercise.** Six block types, four value types, one shape.
- 🎯 **Automation is the payoff of debugging.** Every gotcha in the NAT task is now encoded in a bash script that never fails the same way twice.

---

## Day Status

| Area                                | Status       |
| ----------------------------------- | ------------ |
| 100 Days DevOps — Git reset         | 🟢 Completed |
| 100 Days Cloud — NAT instance       | 🟢 Completed |
| Personal — Terraform (5 tasks)      | 🟢 Completed |
| Git (reset + force push)            | 🟢 Reinforced |
| AWS (NAT instance + routing)        | 🟢 Learned   |
| Terraform (resources, syntax)       | 🟢 Building  |
| NAT automation script               | 🟢 Built     |

**Overall: 🟢 Day 30/100 — Completed**

> **Major realization:** The NAT instance task took hours and failed four times, but the final fix was **one line** — adding a route to the correct route table. Everything else (iptables, source/dest check, security groups, NACLs) was already correct. The lesson isn't "NAT instances are hard." It's "**silent failures mean missing links, and the diagnostic order matters more than the commands**." Network first. Routing second. Firewall third. The signal that broke the deadlock was `FORWARD: 0 packets` — it told me the problem was upstream, not on the instance. That's the debugging skill that separates an engineer from someone who follows tutorials.
