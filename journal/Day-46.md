# CloudOps / DevOps Journal

## Day 46 — 28 October 2026

**Challenges:** 100 Days of DevOps, 100 Days of Cloud, and **Terraform L2 — Day 1**

> **Milestone:** Terraform L2 started. First L2 task attempted independently — 6 errors caught by plan.

---

## 1. 100 Days of DevOps — Dockerfile Fix on App Server 2

**Task:** Fix a failing Dockerfile at `/opt/docker/Dockerfile` (httpd 2.4.43 + SSL + port 8080). Don't change base image, valid config, or data files.

**The issue — `ls -R` showed the layout:**

```
/opt/docker/
├── Dockerfile
├── certs/server.crt, server.key
└── html/index.html
```

**The failing COPY lines pointed at context root, but files were in subdirectories:**

```dockerfile
# ❌ Original
COPY /server.crt /usr/local/apache2/conf/server.crt
COPY /server.key /usr/local/apache2/conf/server.key
COPY ./index.html /usr/local/apache2/htdocs/

# ✅ Fixed
COPY certs/server.crt /usr/local/apache2/conf/server.crt
COPY certs/server.key /usr/local/apache2/conf/server.key
COPY html/index.html /usr/local/apache2/htdocs/
```

**Build:**

```bash
cd /opt/docker
docker build -t httpd-ssl .
```

### Key Learning

**Docker `COPY` paths are always relative to the build context — leading `/` doesn't mean host absolute.** `COPY /server.crt` and `COPY server.crt` both resolve to `<context>/server.crt`. The real problem was missing the subdirectory, not the slash. `ls -R` is the diagnostic — it shows where files actually are.

---

## 2. 100 Days of Cloud — NAT Gateway for Private EC2

**Task:** Private EC2 in `devops-priv-vpc` needs internet for a cron job uploading to S3 `devops-nat-812472022`. Build: public subnet, IGW, public RT, EIP, NAT GW, **new** private RT (not main RT) routed to NAT GW.

**Commands:**

```bash
# Gather IDs
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devops-priv-vpc" --query "Vpcs[0].VpcId" --output text)
PRIV_SUBNET=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=devops-priv-subnet" --query "Subnets[0].SubnetId" --output text)

# 1. Public subnet (same AZ as private)
PUB_SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 \
  --availability-zone "$(aws ec2 describe-subnets --subnet-ids $PRIV_SUBNET --query "Subnets[0].AvailabilityZone" --output text)" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=devops-pub-subnet}]' \
  --query "Subnet.SubnetId" --output text)
aws ec2 modify-subnet-attribute --subnet-id "$PUB_SUBNET" --map-public-ip-on-launch

# 2. IGW
IGW=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=devops-igw}]' --query "InternetGateway.InternetGatewayId" --output text)
aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW"

# 3. Public RT + route + associate
PUB_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=devops-pub-rt}]' --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PUB_RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW"
aws ec2 associate-route-table --route-table-id "$PUB_RT" --subnet-id "$PUB_SUBNET"

# 4. EIP + NAT GW
EIP=$(aws ec2 allocate-address --domain vpc --query "AllocationId" --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id "$PUB_SUBNET" --allocation-id "$EIP" \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=devops-natgw}]' --query "NatGateway.NatGatewayId" --output text)
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT"

# 5. NEW private RT — NOT the main RT
PRIV_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=devops-priv-rt}]' --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$PRIV_RT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT"
aws ec2 associate-route-table --route-table-id "$PRIV_RT" --subnet-id "$PRIV_SUBNET"
```

**Verify:**

```bash
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$PRIV_SUBNET" --query "RouteTables[0].RouteTableId" --output text
# → must equal $PRIV_RT (not the main RT)

aws s3 ls s3://devops-nat-812472022/    # after 2-3 min — cron uploads
```

### Key Learning

**The task explicitly forbids editing the VPC's main route table.** Create `devops-priv-rt`, associate `devops-priv-subnet` to it. The main RT stays untouched. **The grader checks the association, not just that internet works.**

**`wait nat-gateway-available` is required.** `create-nat-gateway` returns immediately with `State: pending`. The route succeeds (`Return: true`) but traffic fails until `available`. The waiter blocks — 1–3 minutes.

---

## 3. Terraform L2 Task 1 — VPC + Subnet with Explicit `depends_on`

**Task:** `datacenter-vpc` + `datacenter-subnet`. Subnet uses `depends_on`. Four files: `main.tf`, `variables.tf`, `terraform.tfvars`, `outputs.tf`. Final `terraform plan` must show `No changes`.

**Files:**

```hcl
# variables.tf — no default, comes from tfvars
variable "KKE_VPC_NAME"    { type = string }
variable "KKE_SUBNET_NAME" { type = string }

# terraform.tfvars
KKE_VPC_NAME    = "datacenter-vpc"
KKE_SUBNET_NAME = "datacenter-subnet"

# main.tf
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = var.KKE_VPC_NAME }
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  tags = { Name = var.KKE_SUBNET_NAME }
  depends_on = [aws_vpc.this]
}

# outputs.tf — lowercase output names, different case from variables
output "kke_vpc_name"    { value = var.KKE_VPC_NAME }
output "kke_subnet_name" { value = var.KKE_SUBNET_NAME }
```

**Verify:**

```bash
terraform apply -auto-approve
terraform plan       # → No changes. Your infrastructure matches the configuration.
```

### Key Learning

**`depends_on` is redundant here — and the task knows it.** `vpc_id = aws_vpc.this.id` already creates the dependency. Terraform builds the graph from references; `depends_on` is an explicit override for hidden dependencies the expression can't express. **Using it here satisfies the task wording but adds nothing functionally.**

**`depends_on` takes resource references, not attribute paths.** `[aws_vpc.this]` ✓, `[aws_vpc.this.id]` ✗.

**Output names are lowercase (`kke_vpc_name`); variable names are uppercase (`KKE_VPC_NAME`).** The task specifies both cases exactly.

**This was the first L2 task — and the first with 4 files instead of 2.** See §6 for the pattern.

---

## 4. Terraform L2 Task 2 — Private VPC + Subnet + EC2 (First Independent Attempt)

**Task:** `devops-priv-vpc` (10.0.0.0/16), `devops-priv-subnet` (10.0.1.0/24, no auto-assign IP), `devops-priv-ec2` (t2.micro), SG allowing access only from VPC CIDR. Variables `KKE_VPC_CIDR` / `KKE_SUBNET_CIDR`. Outputs `KKE_vpc_name` / `KKE_subnet_name` / `KKE_ec2_private`.

**My first attempt — 6 issues found:**

| # | Issue | Fix |
|---|---|---|
| 1 | Outputs as bare assignments | Wrap each in `output "name" { value = ... }` |
| 2 | `aws_subnet` missing `vpc_id` | `vpc_id = aws_vpc.this_vpc.id` |
| 3 | `assign_ipv4_address_on_creation = false` | Argument is `map_public_ip_on_launch` |
| 4 | `resource "aws_ec2"` | Type is `aws_instance` |
| 5 | `ami = ` empty, `instance_type = t2.micro` unquoted | Fill AMI, quote the type |
| 6 | No security group resource | Add one with ingress from `var.KKE_VPC_CIDR` |

**Corrected files:**

```hcl
# variables.tf — mine was correct
variable "KKE_VPC_CIDR"    { type = string; default = "10.0.0.0/16" }
variable "KKE_SUBNET_CIDR" { type = string; default = "10.0.1.0/24" }

# main.tf
provider "aws" { region = "us-east-1" }

resource "aws_vpc" "this_vpc" {
  cidr_block = var.KKE_VPC_CIDR
  tags = { Name = "devops-priv-vpc" }
}

resource "aws_subnet" "this_subnet" {
  vpc_id                  = aws_vpc.this_vpc.id
  cidr_block              = var.KKE_SUBNET_CIDR
  map_public_ip_on_launch = false
  tags = { Name = "devops-priv-subnet" }
}

resource "aws_security_group" "this_sg" {
  name   = "devops-priv-sg"
  vpc_id = aws_vpc.this_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.KKE_VPC_CIDR]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "devops-priv-sg" }
}

resource "aws_instance" "this_ec2" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.this_subnet.id
  vpc_security_group_ids = [aws_security_group.this_sg.id]
  tags = { Name = "devops-priv-ec2" }
}

# outputs.tf
output "KKE_vpc_name"    { value = aws_vpc.this_vpc.tags["Name"] }
output "KKE_subnet_name" { value = aws_subnet.this_subnet.tags["Name"] }
output "KKE_ec2_private" { value = aws_instance.this_ec2.tags["Name"] }
```

**Verify:**

```bash
terraform init && terraform validate && terraform plan && terraform apply -auto-approve
# Plan: 4 to add

terraform output
aws ec2 describe-subnets --filters "Name=tag:Name,Values=devops-priv-subnet" \
  --query "Subnets[0].MapPublicIpOnLaunch" --output text      # → false
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=devops-priv-sg" \
  --query "SecurityGroups[0].IpPermissions[*].IpRanges[*].CidrIp" --output text   # → 10.0.0.0/16
```

### Key Learning

**The four error classes were all shapes the journal has documented all week:**

| My error | Same class as |
|---|---|
| Outputs as bare assignments | Wrong block structure |
| Missing `vpc_id` | Required argument — same as `assume_role_policy` |
| `assign_ipv4_address_on_creation` | Wrong name — same as `--tags-specifications` vs `--tags` |
| `aws_ec2` | Wrong type — same as `aws_instance_delete` |

**"What I can do by myself" was the first draft — the plan caught every gap.** `terraform validate` names wrong type and wrong argument name. `terraform plan` names missing required args. **The loop is the skill — not writing it right the first time.**

---

## 5. K8 Sheet Created

Built the Kubernetes Operator's Manual — same structure as the AWS CLI sheet: Part I (methodology), Part II (pattern library), Part III (playbooks), Part IV (service reference), Part V (tables). Covers pods, deployments, services, configmaps, secrets, jobs, cronjobs, volumes, rollouts, port-forward, exec.

**Deferred to L3/L4:** Ingress, StatefulSets, DaemonSets, NetworkPolicy, RBAC, Helm, HPA, CRDs.

---

## 6. The L1 → L2 Structural Shift

**Observed across the first two L2 tasks:**

| | L1 | L2 |
|---|---|---|
| Files | `main.tf` + `variables.tf` | `main.tf` + `variables.tf` + `outputs.tf` + `terraform.tfvars` |
| Variables | `default = "..."` inline | `type = string` with **no default** — value from tfvars |
| Outputs | Optional / not required | **Explicit deliverables** — grader reads them |
| `depends_on` | Not tested | **Explicit requirement** (Task 1) |

**L1 asked: "Can you write a resource block?"**
**L2 asks: "Can you structure a Terraform module?"**

The resource blocks themselves — `aws_vpc`, `aws_subnet`, `aws_instance` — **stayed identical**. What changed is file organization, where values live, and what the module exposes.

**The three new things and why each matters:**

**`terraform.tfvars` — the config layer.** `variables.tf` is the schema (version-controlled); `terraform.tfvars` holds the values (environment-specific). Task 1's variables had **no `default`** — the value **must** come from tfvars. That's the contract.

**`outputs.tf` — the module's return values.** Same mechanism as child modules — how the parent reads values back. **Naming case matters** — `kke_vpc_name` (lowercase) vs `KKE_vpc_name` (mixed) — copy each from the prompt.

**`depends_on` — explicit when inference isn't enough.** Redundant in Task 1 (already inferred via `vpc_id = aws_vpc.this.id`), required by the task as a **demonstration of the mechanism**. In real code, `depends_on` appears when there's a dependency the expression can't express.

**What stays the same:** every resource block remains `<type>` `<label>` `{ <required args> + tags }`. **L2 is the same loop with more files and more layers.**

---



---

## Key Takeaways

- 🐳 **Docker `COPY` is context-relative.** Leading `/` is stripped. `ls -R` shows where files actually are.
- ☁️ **NAT GW needs a new private RT, not the main RT.** Grader checks the association.
- ☁️ **`wait nat-gateway-available` is required.** Route succeeds while NAT is `pending`.
- 🔧 **L1 → L2 structural shift:** files go from 2 → 4. `variables.tf` schema, `terraform.tfvars` values, `outputs.tf` interface, `depends_on` explicit. **Resource blocks unchanged.**
- 🔧 **`depends_on` is redundant when `vpc_id` already links resources.** Task required it anyway. Form: `[aws_vpc.this]`.
- 🔧 **First independent L2 task: 6 issues caught by plan.** Wrong type, wrong argument name, missing `vpc_id`, bare output assignments, unquoted type, missing SG. **All same error classes as the whole week.**
- 💰 **Terraform L2 + K8 L1 = 3,350 coins.** 1,150 left for K8 L2. 2/day is a ceiling.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Dockerfile fix | 🟢 Completed |
| 100 Days Cloud — NAT Gateway | 🟢 Completed |
| Terraform L2 Task 1 — VPC + Subnet `depends_on` | 🟢 Completed |
| Terraform L2 Task 2 — Private VPC + EC2 | 🟢 Completed (after fixes) |
| K8 sheet | 🟢 Created |

**Overall: 🟢 Day 46/100 — Completed · Terraform L2 Day 1**

> **Realization:** Two firsts today. **The first L2 tasks** — and the plan caught six issues on Task 2, every one a shape the journal has documented since Day 40. `aws_ec2` → `aws_instance` is the same class as `aws_instance_delete` (Day 40). Missing `vpc_id` is the same class as missing `assume_role_policy` (Day 44). `assign_ipv4_address_on_creation` is the same class as `--tags-specifications` (Day 41). **The shapes repeat across every tool; only the vocabulary changes.**
>
> The structural shift matters more than the errors. **L1's 2 files became L2's 4.** `variables.tf` is the schema, `terraform.tfvars` holds the values, `outputs.tf` is the interface, `depends_on` is the explicit dependency override. **The resource blocks didn't change — the organization did.** L1 tested whether I could write a resource. L2 tests whether I can structure a project. **Same loop, one layer up.**
