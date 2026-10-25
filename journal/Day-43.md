# CloudOps / DevOps Journal

## Day 43 — 25 October 2026

**Challenges:** KodeKloud 100 Days of DevOps, 100 Days of Cloud, and Terraform L1

---

## 1. 100 Days of DevOps Challenge

### Task: Create Docker Network `media` with macvlan Driver on App Server 1

I was tasked with:

1. Create a Docker network named `media` on App Server 1
2. Configure it to use the `macvlan` driver
3. Set the subnet to `10.10.1.0/24` and ip-range to `10.10.1.0/24`

### What I Did

**Step 1 — SSH into App Server 1:**

```bash
ssh tony@stapp01
```

**Step 2 — Created the network:**

```bash
docker network create --driver macvlan \
  --subnet 10.10.1.0/24 \
  --ip-range 10.10.1.0/24 \
  media
```

Returned `141d3cb66ddf...` — the network ID. Success on the first attempt.

**Step 3 — Verified:**

```bash
docker network ls | grep media
docker network inspect media
```

Confirmed `Driver: macvlan`, `Subnet: 10.10.1.0/24`, `IPRange: 10.10.1.0/24`.

### Key Learning

**`--subnet` and `--ip-range` are different things even when they're the same value.** `--subnet` declares the whole address space the network occupies. `--ip-range` constrains which subset Docker allocates to containers. Normally `--ip-range` is a *subset* of `--subnet`, allowing a large subnet to be split across hosts (e.g., `--subnet 10.10.1.0/24 --ip-range 10.10.1.128/25` reserves the top half for containers and the bottom half for the gateway and static addresses). The task set them to the same value, which is unusual but valid — it means Docker can allocate any address in the subnet.

**macvlan needs a parent interface, but Docker found one by default.** The full production form is `-o parent=eth0` (or `enX0`, `ens5`) — this tells macvlan which physical interface to attach to. Without it, Docker picks the host's default-route interface. The command succeeded, which means the implicit parent worked. **In production the parent matters** — if the parent interface isn't on the same L2 segment as the subnet's gateway, containers on the network can't reach anything outside. The task doesn't test connectivity, only configuration, so the implicit parent is fine for the grader.

**This was the fastest task of the week** — one command, one verification. The learning was conceptual: knowing what `--ip-range` actually does and why macvlan needs a parent. **The command is easy; knowing what to think about when it isn't** is what compounds.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create DynamoDB Table `nautilus-tasks` and Insert Two Items

I was tasked with:

1. Create a DynamoDB table `nautilus-tasks` with `taskId` (string) as the primary key
2. Insert Task 1: `taskId: '1'`, `description: 'Learn DynamoDB'`, `status: 'completed'`
3. Insert Task 2: `taskId: '2'`, `description: 'Build To-Do App'`, `status: 'in-progress'`
4. Verify both tasks are present with the correct statuses

### What I Did — and the Error Chain

**Attempt 1 — attribute name mismatch:**

```bash
aws dynamodb create-table --table-name nautilus-tasks \
  --attribute-definitions AttributeName=Id,AttributeType=S \
  --key-schema AttributeName=taskId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

```
ValidationException: One or more parameter values were invalid:
Some index key attributes are not defined in AttributeDefinitions.
Keys: [taskId], AttributeDefinitions: [Id]
```

The error names the exact problem: `taskId` is used in the key schema but isn't in the attribute definitions — `Id` is. The two arguments must **agree on the attribute name**.

**Attempt 2 — fixed the mismatch:**

```bash
aws dynamodb create-table --table-name nautilus-tasks \
  --attribute-definitions AttributeName=taskId,AttributeType=S \
  --key-schema AttributeName=taskId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Returned `TableStatus: CREATING`. Success.

**Step 3 — Waited for ACTIVE:**

```bash
aws dynamodb describe-table --table-name nautilus-tasks \
  --query "Table.TableStatus" --output text
```

After ~10 seconds: `ACTIVE`.

**Step 4 — Inserted both items:**

```bash
aws dynamodb put-item --table-name nautilus-tasks \
  --item '{
    "taskId":      {"S": "1"},
    "description": {"S": "Learn DynamoDB"},
    "status":      {"S": "completed"}
  }'

aws dynamodb put-item --table-name nautilus-tasks \
  --item '{
    "taskId":      {"S": "2"},
    "description": {"S": "Build To-Do App"},
    "status":      {"S": "in-progress"}
  }'
```

Both returned nothing — silence is the success signal for `put-item`.

**Step 5 — Verified:**

```bash
aws dynamodb scan --table-name nautilus-tasks \
  --query "Items[].{taskId: taskId.S, description: description.S, status: status.S}" \
  --output table
```

Both rows present with correct statuses. Task complete.

### Issues I Faced and How I Fixed Them

**Issue 1 — `AttributeDefinitions` and `KeySchema` named different attributes**

The error was explicit:

```
Keys: [taskId], AttributeDefinitions: [Id]
```

`--attribute-definitions` **declares** the attributes that will participate in keys. `--key-schema` **uses** those attributes. Every attribute in `--key-schema` must also appear in `--attribute-definitions` with a matching `AttributeName`.

**Fix:** Made both refer to `taskId`.

| Flag | Attribute name |
|---|---|
| `--attribute-definitions AttributeName=taskId,AttributeType=S` | the declaration |
| `--key-schema AttributeName=taskId,KeyType=HASH` | the usage — must match |

**Issue 2 (anticipatory) — Table in `CREATING` state**

`put-item` on a table that's still `CREATING` returns `ResourceNotFoundException`. Waited for `ACTIVE` before inserting.

### Key Learning

**DynamoDB items use typed attribute values, not raw JSON.** Every value in an item is wrapped in a type descriptor:

| Type | Wrapper | Example |
|---|---|---|
| String | `S` | `{"S": "1"}` |
| Number | `N` | `{"N": "42"}` |
| Boolean | `BOOL` | `{"BOOL": true}` |
| List | `L` | `{"L": [{"S": "a"}, {"S": "b"}]}` |
| Map | `M` | `{"M": {"key": {"S": "value"}}}` |
| Null | `NULL` | `{"NULL": true}` |

`"taskId": "1"` would fail. `"taskId": {"S": "1"}` works. **This is the shape DynamoDB's API requires** — and it carries forward to Terraform's `aws_dynamodb_table_item` and to any SDK. Learn it once, use it everywhere.

**`put-item` returns nothing on success.** Compare to `create-table` which returns the whole table description. The absence of output is the signal — not a failure. This is the same shape as `authorize-security-group-ingress` (no output on success) and opposite to `run-instances` (returns everything). **Different services have different success signals — silence is one of them.**

**The `AttributeDefinitions` / `KeySchema` linkage is the same class of error as Day 41's tag shapes.** Both flags look right in isolation, but the API checks that they agree — and the error message names exactly which side is wrong (`Keys: [taskId], AttributeDefinitions: [Id]`). Read the message literally, and the fix is one character.

---

## 3. Personal Tasks — Terraform

### Task A: Create Security Group `nautilus-sg` with Variable `KKE_sg`

I was tasked with:

1. Create a security group named `nautilus-sg`
2. The name should be stored in a variable `KKE_sg`
3. Config values in `variables.tf`; `main.tf` references them

### What I Did — and the Error Chain

**Attempt 1 — two syntax errors in the starting code:**

```hcl
# ❌ WRONG
variable "KKE_sg" {
    name = "nautilus-sg"
}

resource var.KKE_sg {
    name = var.KKE_sg.name
}
```

Two problems:

1. **`variable` has no `name` attribute.** The valid meta-arguments are `default`, `type`, `description`. The name **is** the block label.
2. **`resource` needs two labels** — the resource *type* from the provider (e.g., `aws_security_group`) and a *local name* (any identifier). A variable cannot substitute for either. `var.KKE_sg` is a value, not a block label.

**Fix — corrected `variables.tf`:**

```hcl
variable "KKE_sg" {
  description = "Name of the Security Group"
  type        = string
  default     = "nautilus-sg"
}
```

**Fix — corrected `main.tf`:**

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "nautilus_sg" {
  name        = var.KKE_sg
  description = "Nautilus security group"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = var.KKE_sg
  }
}
```

**Attempt 2 — `terraform plan` failed with a missing data source:**

```
Error: Reference to undeclared resource

  on main.tf line 4, in resource "aws_security_group" "nautilus_sg":
   4:   vpc_id      = data.aws_vpc.default.id

A data resource "aws_vpc" "default" has not been declared in the root module.
```

The `vpc_id` argument requires a VPC ID, and I'd referenced `data.aws_vpc.default.id` without declaring the `data "aws_vpc" "default"` block. Same shape as the variable error — a reference without a declaration.

**Fix — added the data block:**

```hcl
data "aws_vpc" "default" {
  default = true
}
```

**Attempt 3 — plan succeeded:**

```
  # aws_security_group.nautilus_sg will be created
  + resource "aws_security_group" "nautilus_sg" {
      + description = "Nautilus security group"
      + name        = "nautilus-sg"
      + vpc_id      = "vpc-..."
      + tags        = { + "Name" = "nautilus-sg" }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Applied and verified with `describe-security-groups` — SG exists with correct name.

### Key Learning

**`data` blocks are for "already exists" resources — you don't create a VPC that's already there, you look it up.** `data "aws_vpc" "default" { default = true }` says "find the default VPC." The reference `data.aws_vpc.default.id` then resolves to that VPC's actual ID. **Same pattern from Day 38** (`data "aws_iam_user"`, `data "aws_iam_policy"`) — the *whole* resource exists, so `data` is the right tool. Different from a `resource` block that **creates** something new.

**Every reference needs a matching declaration.** This is the third time this week:

| Missing declaration | Reference that failed |
|---|---|
| `variable "KKE_sg"` | `var.KKE_sg` |
| `data "aws_vpc" "default"` | `data.aws_vpc.default.id` |
| `ecsTaskExecutionRole` in AWS (Day 38) | `executionRoleArn` in task definition |

`terraform validate` catches all three in **seconds** — it's an existence check, not just a syntax check. **Run it before plan, every time.** The cost of `validate` is a second; the cost of the missing data source during plan is a confusing error message.

---

### Task B: Create Elastic IP `nautilus-eip` with Variable `KKE_eip`

I was tasked with:

1. Create an Elastic IP named `nautilus-eip`
2. The name should be stored in a variable `KKE_eip`
3. Config values in `variables.tf`; `main.tf` references them

### What I Did — and the Error Chain

**Attempt 1 — unquoted variable label:**

```hcl
# ❌ WRONG
variable KKE_eip {
    description = "Nautilus EIP"
    type = string
    default = "nautilus-eip"
}
```

**In HCL, block labels must be quoted strings.** Every `variable`, `resource`, `data`, `output`, `provider` block follows this rule. The unquoted form is invalid and `terraform validate` rejects it at parse time with:

```
Error: Invalid block definition

  on main.tf line 1:
   1: variable KKE_eip {

Either a quoted string block label or an opening brace ("{") is expected here.
```

**Fix — added the quotes:**

```hcl
variable "KKE_eip" {
  description = "Nautilus Elastic IP"
  type        = string
  default     = "nautilus-eip"
}
```

**Attempt 2 — empty resource body:**

```hcl
resource "aws_eip" "nautilus_eip" {
}
```

This would create an EIP but **without a Name tag** — the grader filtering by `tag:Name=nautilus-eip` would find nothing.

**Fix — added `domain` and the tag:**

```hcl
resource "aws_eip" "nautilus_eip" {
  domain = "vpc"

  tags = {
    Name = var.KKE_eip
  }
}
```

**Attempt 3 — full working config:**

`main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_eip" "nautilus_eip" {
  domain = "vpc"

  tags = {
    Name = var.KKE_eip
  }
}
```

Applied. Verified:

```bash
aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=nautilus-eip" \
  --query "Addresses[].{PublicIp:PublicIp,AllocationId:AllocationId,Domain:Domain}" \
  --output table
```

One EIP with `Domain: vpc` and correct Name tag.

### Key Learning

**`domain = "vpc"` in modern AWS provider, `vpc = true` in old.** The `vpc = true` syntax was deprecated in provider v4. Any tutorial written before mid-2021 will show `vpc = true` — the current correct form is `domain = "vpc"`. **Same class of lesson as `--tag-specifications` vs `--tags` on Day 41** — the tool's vocabulary changed, the tutorials didn't. **Always check the current provider docs for arguments that changed recently**, not an old blog post.

**`domain` isn't strictly required for the grader** — in provider v4+, it defaults to `vpc` and the EIP would be created correctly without it. But including it explicitly documents intent, and it's the value the grader is most likely to expect in `describe-addresses` output. **Explicit is better than implicit when the cost is one line.**

**The empty resource body is the same failure as Day 39's S3 versioning task** — the resource gets created, but without the identifying attribute the grader is looking for. **"Resource exists" and "resource is identifiable" are different things**, and only the second one passes the grader.

---

## The pattern this week has been building

| Day | Variable task | The fix needed |
|---|---|---|
| 42 | VPC with `KKE_vpc` | `variable "KKE_vpc" { default = "datacenter-vpc" }` |
| 43 | SG with `KKE_sg` | Same shape, plus `data "aws_vpc" "default"` |
| 43 | EIP with `KKE_eip` | Same shape, plus quotes around label |

Three variable tasks in two days, all with the **same variable-vs-value shape** — the identifier is `KKE_<thing>`, the value is the human-readable name, and the label goes in quotes. What changed between the tasks was the resource type and the extra arguments each one requires (`vpc_id`, `domain`, `name`).

**What stayed the same:** the variable declaration, the tag reference (`Name = var.KKE_<thing>`), the "values in `variables.tf`, reference in `main.tf`" structure.

**What this teaches:** the *task family* has a stable shape; only the *resource-specific arguments* change. Once you recognize the family (`"X should be stored in a variable named Y"`), you can write the skeleton from memory and look up the resource-specific parts. **The recognition is the skill — the lookup is cheap.**

---

## Timeline Impact

No change from Day 42's recalculation:

| Track | Date | Status |
|---|---|---|
| 100 Days Cloud Day 100 | **22 Dec** | On track |
| 100 Days DevOps Day 100 | **22 Dec** | On track |
| Terraform L1 finish (Task 40 + assessment) | **27 Oct** | On track — 2 tasks left |
| Terraform L2 start | **28 Oct** | On track |
| K8 L1 start | **7 Nov** | On track |
| K8 L2 + Day 67 | **18–19 Nov** | On track |
| Project start | **22 Nov** | On track |

**Two more Terraform L1 tasks until the finish line.** Nothing has slipped since the power outage recalculation.

---

## Key Takeaways

- 🐳 **`--subnet` and `--ip-range` are different.** Subnet declares the address space; ip-range constrains Docker's allocation. Same value is valid (this task) but production splits them to reserve gateway addresses.
- 🐳 **macvlan needs a parent interface.** `-o parent=eth0` in full form. Docker defaults to the host's default-route interface, which usually works for the grader but not necessarily in production.
- ☁️ **`--attribute-definitions` and `--key-schema` must name the same attributes.** `AttributeDefinitions` declares them; `KeySchema` uses them. The error names exactly which side is wrong.
- ☁️ **DynamoDB items use typed attribute values.** `{"S": "1"}` not `"1"`. Type descriptors: `S`, `N`, `BOOL`, `L`, `M`, `NULL`. This shape carries forward to Terraform's `aws_dynamodb_table_item`.
- ☁️ **`put-item` returns nothing on success.** Silence is the signal. Different services have different success signals — read them.
- 🔧 **Block labels in HCL are quoted strings.** `variable "KKE_eip"` not `variable KKE_eip`. Unquoted labels fail at parse time — `terraform validate` catches them in a second.
- 🔧 **`variable` has no `name` attribute.** The valid meta-arguments are `default`, `type`, `description`. The name **is** the label.
- 🔧 **`resource` needs two labels** — type (from provider) and local name (any identifier). A variable cannot substitute for either.
- 🔧 **`data` blocks look up "already exists" resources.** `data "aws_vpc" "default" { default = true }` for the default VPC. Same pattern as Day 38's `data "aws_iam_user"`.
- 🔧 **`domain = "vpc"` is the modern form** — `vpc = true` was deprecated in provider v4. Old tutorials still show the old form. Always check the current provider docs.
- 🔧 **`terraform validate` catches declaration/syntax errors in seconds.** Run it before `plan`, every time. It's an existence check, not just a syntax check.

---

## Day Status

| Area                                              | Status       |
| ------------------------------------------------- | ------------ |
| 100 Days DevOps — Docker macvlan network          | 🟢 Completed |
| 100 Days Cloud — DynamoDB table + items            | 🟢 Completed |
| Personal — Terraform Security Group (variable)     | 🟢 Completed |
| Personal — Terraform Elastic IP (variable)         | 🟢 Completed |
| Docker (network drivers, subnet vs ip-range)       | 🟢 Learned   |
| AWS (DynamoDB table schema, item type descriptors) | 🟢 Learned   |
| Terraform (variable blocks, data sources, v4 syntax) | 🟢 Reinforced |

**Overall: 🟢 Day 43/100 — Completed**

> **Major realization:** Three variable tasks in two days, all the same shape, all with a small variation. The VPC was the introduction. The security group added a `data` source. The Elastic IP added the quote requirement. **The shape is stable; the resource-specific parts are what changes.** That's what a task family *is* — the stable core plus a resource-specific wrapper. Recognizing the family is the skill. The commands inside are lookup.
>
> The other realization is subtler: **every error today was caught by an existence check, not a syntax check.** `terraform validate` catches unquoted labels and missing `data` blocks. The DynamoDB error catches attribute mismatches. The empty `aws_eip` block doesn't error — but `describe-addresses` catches the missing tag. **Two different classes of error, two different tools.** `validate` and `plan` catch syntax and existence. `describe-*` catches the semantic correctness. Running both is what makes the day end clean — not intelligence, not memory, just the double check.
