# CloudOps / DevOps Journal

## Day 40 — 22 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Configure Apache in Container `kkloud` on App Server 1, Listen on Port 8084

I was tasked with:

1. Install `apache2` in the `kkloud` container on App Server 1 (using `apt`)
2. Configure Apache to listen on port `8084` instead of default `80`
3. Ensure it binds on all interfaces (not a specific IP or hostname)
4. Keep the Apache service running and the container up

### What I Did

**Step 1 — SSH into App Server 1:**

```bash
ssh banner@stapp01
sudo su -
```

**Step 2 — Confirmed the container was running:**

```bash
docker ps
```

Saw `kkloud` in the list. Entered it:

```bash
docker exec -it kkloud bash
```

**Step 3 — Installed Apache:**

```bash
apt update
apt install apache2 -y
```

**Step 4 — Changed the port to 8084 in TWO files:**

```bash
# ports.conf — the main listen configuration
sed -i 's/^Listen 80$/Listen 8084/' /etc/apache2/ports.conf

# 000-default.conf — the default virtual host
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8084>/' /etc/apache2/sites-enabled/000-default.conf
```

**Step 5 — Started the service:**

```bash
service apache2 start
```

**Step 6 — Verified:**

```bash
service apache2 status
ss -tlnp | grep 8084
curl -I http://localhost:8084
```

`HTTP/1.1 200 OK`. Task complete.

**Step 7 — Exited without stopping the container:**

```bash
exit
```

### Key Learning

**Changing the Apache port is a two-file operation, not one.** Most tutorials only mention `ports.conf`, which handles where Apache *binds*. But the virtual host in `sites-enabled/000-default.conf` is where the *request routing* happens. If you change only `ports.conf`, Apache listens on 8084 but the default vhost still expects port 80 — and you get "connection refused" on 8084 even though `ss` shows it listening. **Both files must match.**

**`Listen 8084` without an IP is the correct way to bind on all interfaces.** Writing `Listen 127.0.0.1:8084` would restrict to loopback only. Writing `Listen 8084` (port only) makes Apache bind `0.0.0.0:8084` — reachable via `localhost`, `127.0.0.1`, the container IP, and the host's mapped port. The absence of an IP is the requirement, not a shortcut.

**Container state management is part of the task.** `docker exec` puts you inside; `exit` only closes the shell — it does not stop the container. If you had run `docker stop kkloud` after finishing, the grader would fail on requirement (c). The container must remain running at the end.

**This was the quickest task of the week.** The commands were simple; the learning was the two-file dependency. Next time I'd check `apache2ctl configtest` before starting, to catch a bad `sed` match immediately rather than debugging an unresponsive port after `service apache2 start`.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Fix VPC Connectivity for `devops-ec2` — Website Inaccessible from Internet

I was tasked with:

1. Verify VPC `devops-vpc` is properly configured for internet access
2. Ensure `devops-ec2` (running Nginx) is accessible from the internet on port 80

The task prompt said: *"the team suspects that the issue might be related to the VPC configuration, as all other components appear to be set up correctly."*

### What I Did

**Step 1 — Looked at the current state:**

```bash
aws ec2 describe-internet-gateways
```

Output showed two IGWs:

```json
{
  "InternetGateways": [
    {
      "Attachments": [],
      "InternetGatewayId": "igw-000afb63744dfb529",
      "Tags": [{"Key": "Name", "Value": "devops-ig"}]
    },
    {
      "Attachments": [{"State": "available", "VpcId": "vpc-02d896bb54fe8a905"}],
      "InternetGatewayId": "igw-08fd562bcb0c1430f",
      "Tags": []
    }
  ]
}
```

**The clue was there in the first output**: `devops-ig` (`igw-000afb63744dfb529`) had `"Attachments": []` — **not attached to any VPC**. The other IGW was attached to the *default* VPC, not `devops-vpc`.

**Step 2 — Confirmed `devops-vpc` had no attached IGW:**

```bash
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-0ee54d2e3638491aa"
```

Output: `{"InternetGateways": []}`

That empty array was the diagnosis. **An IGW exists, but it's not attached to the VPC that needs it.**

**Step 3 — Found the VPC ID by name:**

```bash
aws ec2 describe-vpcs --filter "Name=tag:Name,Values=devops-vpc"
```

Got `vpc-0ee54d2e3638491aa`. Confirmed it was **not** the default VPC and had CIDR `10.0.0.0/16`.

**Step 4 — Attached the IGW:**

```bash
aws ec2 attach-internet-gateway \
  --vpc-id vpc-0ee54d2e3638491aa \
  --internet-gateway igw-000afb63744dfb529
```

(First attempt had `--internet-gateway` — the correct flag is `--internet-gateway-id`. Also tried `--vpc-id Values=vpc-...` once, which failed with `InvalidVpcId.Malformed` — because `Values=` is filter syntax, not an ID syntax. Two quick corrections, then it worked.)

**Step 5 — Verified route tables:**

```bash
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0ee54d2e3638491aa"
```

Three route tables existed:
- **`rtb-01118b00a68bdd639`** (main RTB) — only local route, no `0.0.0.0/0 → IGW`
- **`rtb-0d7659cef6ff8f8cb`** (`devops-rtb`) — associated with `subnet-018fadc05d0e2e4e8`, **has `0.0.0.0/0 → igw-000afb63744dfb529`, state active**
- **`rtb-0f8729e78c872d0ca`** (`internet-rtb`) — has `0.0.0.0/0 → igw`, **no associations** (orphan — I created this in a hurry before realizing it wasn't needed)

**Step 6 — Confirmed the instance's subnet was already on the correct RTB:**

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=devops-ec2" \
  --query "Reservations[].Instances[].{InstanceId:InstanceId,SubnetId:SubnetId,PublicIp:PublicIpAddress,SGs:SecurityGroups[*].GroupId}" \
  --output table
```

Output: `i-02b07d10633a98029`, **public IP `13.218.177.240`**, subnet `subnet-018fadc05d0e2e4e8`, SG `sg-0a655307bd5c99380`.

Then:

```bash
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-018fadc05d0e2e4e8"
```

Confirmed `subnet-018fadc05d0e2e4e8` was on `rtb-0d7659cef6ff8f8cb` — **which had the IGW route**. So the subnet routing was already correct.

**Step 7 — Verified the fix:**

```bash
curl -sI http://13.218.177.240
```

`200 OK`. Task complete.

### Issues I Faced and How I Fixed Them

**Issue 1 — Wrong flag name (`--internet-gateway` vs `--internet-gateway-id`)**

The flag is `--internet-gateway-id`, not `--internet-gateway`. First attempt failed.

**Fix:** Read the help output. `aws ec2 attach-internet-gateway help` lists `--internet-gateway-id <value>` as the required flag.

**Issue 2 — `Values=` prefix in an ID argument**

```bash
aws ec2 attach-internet-gateway --vpc-id Values=vpc-0ee54d2e3638491aa --internet-gateway igw-000afb63744dfb529
```

```
InvalidVpcId.Malformed: Invalid id: "Values=vpc-0ee54d2e3638491aa" (expecting "vpc-...")
```

`Values=` is for `--filters`. When the flag is `--vpc-id`, the value is just the raw ID.

**Fix:** `--vpc-id vpc-0ee54d2e3638491aa`.

**Issue 3 — Misdiagnosed the problem in the middle**

After `describe-route-tables` showed I'd created `internet-rtb` with the correct route but no associations, I momentarily thought the fix was to associate `internet-rtb` with the subnet — or to add the IGW route to the main RTB. **That would have been redundant**: the subnet was already on `devops-rtb`, which already had the route. The only real fix was attaching the IGW — which I'd already done.

**Fix:** Ran `describe-route-tables --filters "Name=association.subnet-id,Values=<subnet>"` to see where the subnet's traffic actually went. That one command cleared the confusion.

### Key Learning

**The IGW existing ≠ the IGW being attached.** AWS allows you to create an IGW and leave it detached — it's just sitting there, doing nothing. The `"Attachments": []` field is the signal: *the IGW exists, but it's not wired to any VPC*. An empty `Attachments` array means the IGW is functionally inert.

**The three-layer check for internet reachability — do all three, in this order:**

| Layer | Command | What "good" looks like |
|---|---|---|
| **IGW attached** | `describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<vpc>"` | Non-empty array with `State: available` |
| **Subnet's RTB has IGW route** | `describe-route-tables --filters "Name=association.subnet-id,Values=<subnet>"` | `0.0.0.0/0 → igw-...`, state `active` |
| **Instance has public IP** | `describe-instances --filters "Name=tag:Name,Values=<name>"` | `PublicIpAddress` not null |

If any of these is missing, the instance cannot reach the internet — even if the security group is wide open. **The layers are sequential**, not independent. A perfect SG cannot rescue a missing IGW.

**Empty arrays from a filter are diagnostic.** `describe-internet-gateways --filters "Name=attachment.vpc-id,..."` returning `{"InternetGateways": []}` was not a failed command — it was the *answer*. The absence was the finding. Same discipline as `get-role` → `NoSuchEntity` from Day 38: you don't need an error to prove absence; the empty result *is* the error.

**Verify, don't trust the prompt.** The task said "all other components appear to be set up correctly." They were — mostly. The IGW existed, the route table had the right route, the SG was presumably fine, the instance had a public IP. **But the IGW wasn't attached.** The prompt's framing was correct *and* incomplete — the missing piece was invisible to a casual look at the IGW list, only visible through a filtered describe. **Filtered `describe-*` before touching anything is what caught it.**

**This is the first task I solved entirely on my own** — no coaching, no second opinion, no walk-through. The diagnostic path was:

1. `describe-internet-gateways` (unsorted) → spotted `"Attachments": []`
2. `describe-internet-gateways --filters "Name=attachment.vpc-id,..."` → empty → confirmed the suspicion
3. `describe-vpcs --filter "Name=tag:Name,..."` → got the VPC ID
4. `attach-internet-gateway` (after two flag errors)
5. `describe-route-tables` → saw everything else was already correct
6. `describe-route-tables --filters "Name=association.subnet-id,..."` → confirmed the subnet's RTB
7. `curl -sI <public-ip>` → `200 OK`

That sequence — **look → narrow → confirm → fix → verify** — is the pattern. It's not luck. It's the same discipline the whole week has been building.

---

## 3. Personal Task — Terraform

### Task: Delete EC2 Instance `nautilus-ec2` via Terraform While Preserving Provisioning Code

I was tasked with:

1. Delete the EC2 instance named `nautilus-ec2` in `us-east-1` using Terraform
2. **Keep the provisioning code** — we might need to provision it again later
3. Verify the instance is in `terminated` state before submission

### What I Did

**The provided starting code contained an invalid resource:**

```hcl
resource "aws_instance_delete" "del_ec2" {
  instance = aws_instance.ec2.id
}
```

`aws_instance_delete` is **not a real Terraform resource type** — it doesn't exist in the AWS provider. Running `terraform apply` would fail with `Invalid resource type` before anything else executed.

**Step 1 — Removed the invalid `aws_instance_delete` block**, leaving the provisioning code intact:

```hcl
resource "aws_instance" "ec2" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    "sg-f99442ab191050950"
  ]

  tags = {
    Name = "nautilus-ec2"
  }
}
```

**Step 2 — Ran a targeted destroy:**

```bash
terraform destroy -target=aws_instance.ec2
```

Terraform planned the destruction of only `aws_instance.ec2`, prompted for confirmation, and completed.

**Step 3 — Verified instance state:**

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nautilus-ec2" \
  --query "Reservations[].Instances[].State.Name" \
  --output text
```

Output: `terminated`. ✅

**Step 4 — Verified state file:**

```bash
terraform state list
```

`aws_instance.ec2` no longer appears — it's been removed from state. The `main.tf` still contains the full resource block, ready for re-provisioning.

### Key Learning

**There is no `aws_instance_delete` resource. Deletion in Terraform is not a resource — it's a verb on the resource's lifecycle.** Every `resource` block in Terraform describes a thing that will be created if absent and destroyed if present and no longer in config. You don't write "now delete it" as a separate resource. You either:

- **`terraform destroy`** — destroys everything in the working directory
- **`terraform destroy -target=<resource>`** — destroys a specific resource, leaves the rest
- **Remove the block from `main.tf` and `terraform apply`** — Terraform sees the resource in state but not in config, and destroys it
- **`removed { from = ... }` block** — tells Terraform to forget the resource *without* destroying it (the opposite of what I needed)

The provided code was trying to express "destroy this resource but keep the code." Terraform has no separate verb for that — the answer is `-target` on the destroy command.

**`-target` is surgical.** Plain `terraform destroy` destroys *everything* in the state — if the working directory has other resources (networking, IAM, databases), those go too. `-target=aws_instance.ec2` touches exactly one resource and one resource only. That's the correct tool when the task explicitly says "keep the provisioning code, we might need this again."

**"Terminated" is asynchronous — verify, don't trust the command's return.** `terraform destroy` returned success, but "success" means "Terraform finished submitting the termination API call." AWS may still be transitioning `shutting-down` → `terminated`. `describe-instances` is the only source of truth.

**The invalid resource block is a teaching moment.** The task gave code with a made-up resource type — and the temptation was to "fix" the code by writing more HCL. But the correct fix was to **delete code**, not add it. **The starting code was wrong in a way that only the CLI's error would reveal** — the shape looked plausible because "delete" is a real verb. Trusting the shape over the API is the same mistake from Day 39 (ACLs vs policies) and from the earlier `Values=` mis-step. The pattern: *when a shape looks right but the tool rejects it, the shape is wrong — not the tool.*

---

### Task: Delete IAM Group via Terraform

Briefly: an existing IAM group needed to be removed via Terraform, keeping the group's policy attachment code intact. The pattern is the same as the EC2 case:

1. If the group is managed by Terraform, `terraform destroy -target=aws_iam_group.<name>`
2. If it's not (imported or unmanaged), the group policy attachments and users must be detached/destroyed first, since IAM won't let you delete a group with attached resources

**Key point:** IAM deletion has a dependency chain — you cannot delete a group that has policies attached or users in it. The order matters:

```
Delete policy attachments → Remove users from group → Delete group
```

If Terraform tries to destroy `aws_iam_group` while `aws_iam_group_policy_attachment` still exists, it fails with `DeleteConflict`. On a `-target` destroy, you have to target all three (attachment, membership, group) together, or destroy in dependency order.

The `depends_on` graph handles this automatically on a full `terraform destroy` — Terraform knows the attachment depends on the group and destroys the attachment first. But `-target` skips the graph traversal, so you have to name every resource in the chain.

---

## Key Takeaways

- 🐳 **Apache port change requires two files.** `ports.conf` sets the binding port; `sites-enabled/000-default.conf` sets the vhost port. Change both or the site stays unreachable.
- 🐳 **`Listen 8084` (no IP) binds on `0.0.0.0`.** Apache binds all interfaces; adding an IP restricts it. For "listen on all interfaces" requirements, omit the IP.
- 🐳 **`docker exec` + `exit` doesn't stop the container.** The container keeps running after you leave the shell.
- ☁️ **IGW existing ≠ IGW attached.** `"Attachments": []` on an IGW means the IGW is inert — not attached to any VPC — and doesn't provide internet access even if the route tables reference it.
- ☁️ **Empty filter results are diagnostic.** `describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<vpc>"` returning `[]` is the finding, not the failure. Absence is information.
- ☁️ **The three-layer internet check:** IGW attached → subnet's route table has IGW route → instance has public IP. All three are required, in that order, before you can debug SG.
- ☁️ **Filtered `describe-*` is your first move.** Running the unfiltered describe gives you a wall of JSON; the filtered one gives you the answer. This task was solved because the second command returned `[]`.
- 🔧 **`aws_instance_delete` doesn't exist.** Terraform has no "delete resource" resource. Deletion is a lifecycle verb: `terraform destroy -target=<resource>`. To keep the code but destroy the resource, `-target` is the only correct tool.
- 🔧 **`-target` is surgical, plain `destroy` is total.** When the working directory has other resources, `-target` protects them. When it doesn't, either works.
- 🔧 **"Terminated" is a state, not a command response.** `terraform destroy` returning success ≠ instance terminated. `describe-instances` showing `terminated` is the only proof.
- 🔧 **IAM deletion has a dependency chain.** Policy attachments → user membership → group. `DeleteConflict` if you try to skip. Full `destroy` handles this via the dependency graph; `-target` requires you to target the chain.

---

## Day Status

| Area                                       | Status       |
| ------------------------------------------ | ------------ |
| 100 Days DevOps — Apache on container port | 🟢 Completed |
| 100 Days Cloud — VPC connectivity fix      | 🟢 Completed |
| Personal — Terraform EC2 targeted destroy  | 🟢 Completed |
| Personal — Terraform IAM group delete      | 🟢 Completed |
| Docker (port config, container state)      | 🟢 Learned   |
| AWS (VPC layering, filtered describes)     | 🟢 Reinforced |
| Terraform (targeted destroy, invalid types) | 🟢 Learned  |

**Overall: 🟢 Day 40/100 — Completed**

> **Major realization:** Today produced the single best proof that the daily journal is working — because I solved the VPC task on my own, using the exact diagnostic sequence the last 40 days had been building. Not because I'm smarter than yesterday, but because yesterday I ran `describe-*` before touching things, and today I did it again. **The discipline compounded.**
>
> The other realization is humbling: **the task said "all other components appear to be set up correctly," and they mostly were — but the one thing that wasn't correct wasn't visible to a casual look.** The IGW was right there in the list, with a Name tag, looking healthy. Only `--filters "Name=attachment.vpc-id,..."` exposed that it wasn't attached. **The difference between "the object exists" and "the object is wired in" is the difference between "the write succeeded" and "the system works."** That's been the theme all week — Day 38 (execution role existed vs. task could assume it), Day 39 (bucket policy existed vs. public access actually worked), today (IGW existed vs. attached to the VPC).
>
> And then Terraform taught the opposite lesson in a new shape: **sometimes the fix isn't writing more code, it's deleting the code that shouldn't exist.** `aws_instance_delete` looked like a resource because it had the right shape — `aws_instance_<verb>`. But the resource type doesn't exist. **The tool's vocabulary is finite; the shape of a word doesn't imply it's real.** Same class of mistake as `--vpc-id Values=vpc-...` — the value looked like a VPC ID, so I used it; the flag rejected it, because an ID argument is not a filter. **The API's rules are narrower than our assumptions about them. Always read the shape from the tool, not from the pattern.**
