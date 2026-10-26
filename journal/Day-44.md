# CloudOps / DevOps Journal

## Day 44 — 26 October 2026

**Challenges:** KodeKloud 100 Days of DevOps, 100 Days of Cloud, and Terraform L1

---

## 1. 100 Days of DevOps Challenge

### Task: Nginx Container `ecommerce` on App Server 1 with Port Mapping

I was tasked with:

1. Pull `nginx:stable` on App Server 1
2. Create a container `ecommerce` from that image
3. Map host port `6300` to container port `80`
4. Keep the container running

### What I Did — and the Miss

**Step 1 — SSH and run (first attempt):**

```bash
ssh tony@stapp01
docker run --name ecommerce -d nginx:stable
```

The image pulled, the container started, `docker ps` showed it running. **Looked like success.**

**Step 2 — Verification caught the miss:**

```bash
docker port ecommerce
# (no output)

docker port ecommerce 6300
# Error: No public port '6300' published for ecommerce

docker port ecommerce 80
# Error: No public port '80' published for ecommerce
```

**Zero port mappings.** I'd created the container without `-p 6300:80` — the fourth and most important requirement was missing, and the container's success message didn't announce it.

**Step 3 — The fix (recreate, not update):**

```bash
docker rm -f ecommerce
docker run -d --name ecommerce -p 6300:80 nginx:stable
```

**Step 4 — Verified properly:**

```bash
docker port ecommerce
# → 80/tcp -> 0.0.0.0:6300

curl -I http://localhost:6300
# → HTTP/1.1 200 OK
```

### Key Learning

**Port mappings are immutable after container creation.** Unlike restart policy or resource limits (which `docker update` can change on a live container), ports and volumes are baked into the container's network namespace and filesystem at creation time. The kernel has already bound the sockets. To change the mapping, you **must** `docker rm` and `docker run` again.

**`docker port <container> <port>` takes the container port, not the host port.** That's why `docker port ecommerce 6300` failed while `docker port ecommerce 80` was the right query (it just had no mapping to report). The output shows both sides — the query takes the left one:

```
80/tcp -> 0.0.0.0:6300
 ─┬──        ────┬────
container    host     ← query takes this side
```

**The image doesn't need re-pulling.** `docker run` uses the local image if present. So the recreate is two commands, not three.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create EKS Cluster `xfusion-eks` with Private Endpoint

I was tasked with:

1. Create an EKS cluster named `xfusion-eks` with Custom configuration
2. Use the IAM role `eksClusterRole` for the cluster
3. Latest stable Kubernetes version
4. Private endpoint only (`endpointPublicAccess=false`, `endpointPrivateAccess=true`)
5. Default VPC, availability zones a, b, and c
6. EKS Auto Mode disabled

### What I Did — and the Error Chain

**Step 1 — Checked the cluster role existed:**

```bash
aws iam get-role --role-name eksClusterRole
# NoSuchEntity: The role with name eksClusterRole cannot be found.
```

The role didn't exist. Created it with the correct trust principal:

```bash
cat > /tmp/eks-trust.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF

aws iam create-role --role-name eksClusterRole \
  --assume-role-policy-document file:///tmp/eks-trust.json

aws iam attach-role-policy --role-name eksClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

**Step 2 — Gathered the default VPC and subnets in AZs a/b/c:**

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

SUBNET_A=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=us-east-1a" \
  --query "Subnets[0].SubnetId" --output text)
# (same for B and C)
```

**Step 3 — Create attempt 1 — failed on Auto Mode config:**

```bash
aws eks create-cluster --name xfusion-eks \
  --role-arn arn:aws:iam::734081570291:role/eksClusterRole \
  --kubernetes-version "$K8S_VERSION" \
  --resources-vpc-config subnetIds=$SUBNET_A,$SUBNET_B,$SUBNET_C,endpointPublicAccess=false,endpointPrivateAccess=true \
  --compute-config enabled=false,nodePools=[],nodeRoleArn="" \
  --access-config authenticationMode=API_AND_CONFIG_MAP,bootstrapClusterCreatorAdminPermissions=true
```

```
InvalidParameterException: For EKS Auto Mode, please ensure that all required configs,
including computeConfig, kubernetesNetworkConfig, and blockStorage are all either
fully enabled or fully disabled.
```

**Step 4 — Fixed by disabling all three Auto Mode capabilities explicitly:**

```bash
aws eks create-cluster --name xfusion-eks \
  --role-arn arn:aws:iam::734081570291:role/eksClusterRole \
  --kubernetes-version "$K8S_VERSION" \
  --resources-vpc-config subnetIds=$SUBNET_A,$SUBNET_B,$SUBNET_C,endpointPublicAccess=false,endpointPrivateAccess=true \
  --compute-config enabled=false \
  --kubernetes-network-config '{"elasticLoadBalancing":{"enabled": false}}' \
  --storage-config '{"blockStorage":{"enabled": false}}' \
  --access-config authenticationMode=API_AND_CONFIG_MAP,bootstrapClusterCreatorAdminPermissions=true
```

Succeeded. `TableStatus: CREATING` returned.

**Step 5 — Waited and verified:**

```bash
aws eks wait cluster-active --name xfusion-eks

aws eks describe-cluster --name xfusion-eks \
  --query 'cluster.{Status:status,Version:version,PrivateEndpoint:resourcesVpcConfig.endpointPrivateAccess,PublicEndpoint:resourcesVpcConfig.endpointPublicAccess,AutoModeCompute:computeConfig.enabled}' \
  --output table
```

All five fields correct: `ACTIVE`, target version, `PrivateEndpoint: True`, `PublicEndpoint: False`, `AutoModeCompute: False`.

### Issues I Faced and How I Fixed Them

**Issue 1 — `eksClusterRole` didn't exist (`NoSuchEntity`)**

The task said "use IAM role for the cluster named `eksClusterRole`," but the lab hadn't pre-created it. This was the *expected* result of the check — the `get-role` was the diagnostic, and "no" was the answer that triggered creation.

**Fix:** Created the role with trust principal **`eks.amazonaws.com`** (not `ec2.amazonaws.com`) and attached `AmazonEKSClusterPolicy`.

**Issue 2 — Auto Mode "all-or-nothing" constraint**

`--compute-config enabled=false` alone was rejected. The EKS API requires the three Auto Mode capabilities — **compute**, **kubernetesNetworkConfig** (load balancing), and **storage** (block storage) — to be **all enabled or all disabled** in the same request. Providing only one sends a contradictory signal.

**Fix:** Added `--kubernetes-network-config '{"elasticLoadBalancing":{"enabled": false}}'` and `--storage-config '{"blockStorage":{"enabled": false}}'` alongside `--compute-config enabled=false`.

### Key Learning

**Every AWS service has exactly one correct trust principal — and it's not always the obvious one.**

| Role | Trust principal |
|---|---|
| EC2 instance role | `ec2.amazonaws.com` |
| Lambda | `lambda.amazonaws.com` |
| ECS execution role | `ecs-tasks.amazonaws.com` ← **not** `ecs.amazonaws.com` |
| EKS **cluster** | `eks.amazonaws.com` |
| EKS **node** | `ec2.amazonaws.com` ← **not** `eks.amazonaws.com` |

**This is the third time this lesson has landed** (Day 37 EC2 role, Day 38 ECS role, today EKS cluster role). The pattern is `<service>.amazonaws.com` — with ECS as the notable exception. Getting it wrong produces a role that exists, looks correct, and fails only when the service tries to assume it — sometimes minutes later, sometimes silently.

**EKS cluster role and EKS node role are different roles.** Cluster role: trust `eks.amazonaws.com`, policy `AmazonEKSClusterPolicy`. Node role: trust `ec2.amazonaws.com`, three policies (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`). Conflating them is the most common EKS setup failure.

**Auto Mode is a three-part bundle.** Compute, load balancing, and block storage must be enabled or disabled together. Partial configuration is rejected at the API. **The error names all three explicitly** — same diagnostic clarity as the DynamoDB `AttributeDefinitions` mismatch and the KMS `AccessControlListNotSupported`.

**`kubectl get nodes` returning "No resources found" after `update-kubeconfig` is success, not failure.** It means kubectl authenticated to the API server successfully — the cluster is reachable — and there simply are no worker nodes or Fargate profiles yet. The absence of nodes is the expected state at this point in the task.

**Private endpoints require in-VPC access.** With `endpointPrivateAccess=true` and `endpointPublicAccess=false`, the cluster's API server is only reachable from inside the VPC. `kubectl` commands must run from a host in the VPC (like `aws-client`). From outside, they'll time out — by design.

---

## 3. Personal Tasks — Terraform

### Task A: Create IAM User with Variable

I was tasked with creating an IAM user via Terraform, with the user name stored in a `KKE_<thing>` variable — the same task family as Day 42 (VPC `KKE_vpc`) and Day 43 (SG `KKE_sg`, EIP `KKE_eip`).

### What I Did

Followed the now-familiar shape:

**`variables.tf`:**

```hcl
variable "KKE_user" {
  description = "Nautilus IAM user"
  type        = string
  default     = "<user-name>"
}
```

**`main.tf`:**

```hcl
resource "aws_iam_user" "user" {
  name = var.KKE_user

  tags = {
    Name = var.KKE_user
  }
}
```

Applied and verified:

```bash
aws iam get-user --user-name <user-name> \
  --query "User.{Name:UserName,Arn:Arn}" --output table
```

### Key Learning

**This was the fifth variable task in four days** — VPC, SG, EIP, IAM user, IAM role. Every one uses the **same two-line variable block** and the **same tag reference**. What changes is the resource type and the **required arguments the resource needs beyond the name**.

| Task | Resource | Required beyond `name` |
|---|---|---|
| Day 42 — VPC | `aws_vpc` | `cidr_block` |
| Day 43 — SG | `aws_security_group` | `description`, `vpc_id` |
| Day 43 — EIP | `aws_eip` | `domain` |
| Today — User | `aws_iam_user` | (none — `name` alone works) |
| Today — Role | `aws_iam_role` | `assume_role_policy` |

**The variable pattern is stable; the resource contract is what changes.** `terraform plan` is the contract checker — it names every missing required argument before the AWS call is made.

---

### Task B: Create IAM Role `iamrole_ammar` with Variable `KKE_iamrole`

I was tasked with creating an IAM role via Terraform, with the role name `iamrole_ammar` stored in a variable `KKE_iamrole`.

### What I Did — and the Error Chain

**Attempt 1 — missing `assume_role_policy`:**

```hcl
resource "aws_iam_role" "ammar" {
    name = var.KKE_iamrole
}
```

```
Error: Missing required argument

  on main.tf line 1, in resource "aws_iam_role" "ammar":
   1: resource "aws_iam_role" "ammar" {

The argument "assume_role_policy" is required, but no definition was found.
```

The error named the exact missing argument. Fixed:

```hcl
resource "aws_iam_role" "ammar" {
    name = var.KKE_iamrole

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}
```

**Attempt 2 — three bugs in the trust policy:**

```hcl
# ❌ WRONG
assume_role_policy = jsonencode({
    Version = "12-10-17"                                    # Bug 1
    Statement = [{
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com}          # Bug 2 — no closing quote
        Action = "Sts:AssumeRole"                            # Bug 3
    }]
})
```

| Bug | What it would cause |
|---|---|
| `"12-10-17"` | `MalformedPolicyDocument` — dropped `20` from the front of the only valid version string |
| `"ec2.amazonaws.com}` | `Invalid string literal` at **validate time** — unterminated quote |
| `"Sts:AssumeRole"` | **Silent risk** — valid JSON, valid HCL, but wrong case on the action namespace |

**Fix — all three corrected:**

```hcl
assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
    }]
})
```

**Step 3 — Applied and verified:**

```bash
terraform validate
terraform plan
terraform apply -auto-approve

aws iam get-role --role-name iamrole_ammar \
  --query "Role.AssumeRolePolicyDocument" --output json
```

The stored policy confirmed `sts:AssumeRole` (lowercase `sts`) and `"Version": "2012-10-17"`.

### Issues I Faced and How I Fixed Them

**Issue 1 — `assume_role_policy` is required, not optional**

`aws_iam_role` has only one required argument beyond `name`: `assume_role_policy`. Without it, the AWS API has no way to know who can assume the role — the creation call would be rejected even if Terraform didn't catch it first. The plan-time error came **before** any AWS call, which is the cheapest possible place to fail.

**Fix:** Added the trust policy with `jsonencode`.

**Issue 2 — Three separate bugs in the trust policy block**

Each is a different error class:

- **`"12-10-17"`** — a typo that produces valid JSON, valid HCL, and is only caught by the AWS API on apply
- **`"ec2.amazonaws.com`** — a syntax error that fails `terraform validate` instantly
- **`"Sts:AssumeRole"`** — case error that produces valid JSON and valid HCL, may not error at the API, and is the most dangerous

**Fix:** All three corrected in one pass.

### Key Learning

**`jsonencode` protects against JSON syntax errors — not against wrong values.** It will happily produce valid JSON for `"12-10-17"` and `"Sts:AssumeRole"`. It will fail on the unterminated quote because that's an HCL parse error, not a JSON error. **This is the same lesson as `terraform validate` on Day 43** — local tools catch syntax and shape; only the AWS API catches semantic validity; and some semantic errors pass *both*.

**The three bug classes are distinct, and only one is silent:**

| Class | Example | Caught by | Risk |
|---|---|---|---|
| Syntax | Unterminated quote | `terraform validate` (instant) | None — fails locally |
| Value | `"12-10-17"` vs `"2012-10-17"` | AWS API on apply | Low — loud failure |
| **Case** | `"Sts"` vs `"sts"` | **Maybe nothing** | **High — silent** |

**The silent one is the one to fear.** `"Sts:AssumeRole"` might be normalized by the AWS parser. It might be rejected. It might be accepted but not work when the service tries to assume the role — which won't surface until minutes or hours later, when a completely different task fails. **Same shape as Day 41's `--query Encrypted.bin`:** the command that doesn't error is the one that costs hours.

**Always `get-role` after `apply` and read the stored policy, not just the apply success message.** The apply says "resource created." Only `get-role` says "policy is correct."

**The `ec2.amazonaws.com` principal was a guess.** The task didn't specify which service assumes the role. `ec2.amazonaws.com` is the safe default for a generic IAM role task. **If the grader expects a different service, the fix is one string** — the trust policy shape stays identical. The lesson: `assume_role_policy` requires *some* principal; the *right* principal is a judgment call the task wording should answer.

---

## The pattern across the week

| Day | Variable task | Resource-specific argument |
|---|---|---|
| 42 | VPC `KKE_vpc` | `cidr_block` |
| 43 | SG `KKE_sg` | `description`, `vpc_id` (+ `data "aws_vpc"`) |
| 43 | EIP `KKE_eip` | `domain` |
| 44 | IAM user | (none — `name` alone) |
| 44 | IAM role `KKE_iamrole` | **`assume_role_policy`** |

**Five variable tasks in three days, same variable pattern, different required arguments each time.** The variable block is now muscle memory. What varies — and what `terraform plan` catches — is the resource's contract.

---

## Timeline Impact

No change:

| Track | Date | Status |
|---|---|---|
| 100 Days Cloud Day 100 | **22 Dec** | On track |
| 100 Days DevOps Day 100 | **22 Dec** | On track |
| Terraform L1 finish | **27 Oct** | Tomorrow — Task 40 + assessment |
| Terraform L2 start | **28 Oct** | On track |
| K8 L1 start | **7 Nov** | On track |
| Project start | **22 Nov** | On track |

**Tomorrow is the Terraform L1 finish line** — Task 40 plus the assessment on the same day. Today was the last practice run before that.

---

## Key Takeaways

- 🐳 **Port mappings are immutable after container creation.** `docker update` can change restart policy and resource limits — not ports or volumes. Recreate: `docker rm -f <c> && docker run -d --name <c> -p <h>:<c> <image>`.
- 🐳 **`docker port <container> <port>` takes the container port, not the host port.** `docker port ecommerce 6300` queries the host side and always fails — `docker port ecommerce 80` is the right query.
- ☁️ **EKS cluster role trust principal is `eks.amazonaws.com`** — not `ec2.amazonaws.com`. EKS *node* role is `ec2.amazonaws.com`. Different roles, different principals.
- ☁️ **EKS Auto Mode is a three-part bundle.** Compute, load balancing, and block storage must be all enabled or all disabled. Partial config is rejected — the error names all three.
- ☁️ **`kubectl get nodes` returning "No resources found" after `update-kubeconfig` is success.** The API server is reachable; there just aren't any nodes yet.
- 🔧 **`aws_iam_role` requires `assume_role_policy`.** Without it, `terraform plan` fails before any AWS call — the plan is the contract checker.
- 🔧 **`jsonencode` catches JSON syntax errors, not wrong values.** It'll happily produce valid JSON for `"12-10-17"` and `"Sts:AssumeRole"`.
- 🔧 **Case errors are the silent killers.** `"Sts:AssumeRole"` may be normalized, may be rejected, may silently not work. `get-role` after `apply` and read the stored policy — that's the only defense.
- 🔧 **Every AWS service has exactly one correct trust principal.** `<service>.amazonaws.com` — with ECS as the exception (`ecs-tasks.amazonaws.com`). Three lessons this week on the same pattern.
- 📝 **The variable task family is stable; the resource contract is what changes.** VPC needs `cidr_block`, SG needs `vpc_id`, EIP needs `domain`, role needs `assume_role_policy`. `terraform plan` names each missing piece.

---

## Day Status

| Area                                          | Status       |
| --------------------------------------------- | ------------ |
| 100 Days DevOps — nginx container port mapping | 🟢 Completed |
| 100 Days Cloud — EKS cluster                   | 🟢 Completed |
| Personal — Terraform IAM user (variable)       | 🟢 Completed |
| Personal — Terraform IAM role (variable)       | 🟢 Completed |
| Docker (port immutability, recreate pattern)   | 🟢 Reinforced |
| AWS (EKS, Auto Mode, cluster vs node role)     | 🟢 Learned   |
| Terraform (assume_role_policy, trust policy)   | 🟢 Learned   |

**Overall: 🟢 Day 44/100 — Completed**

> **Major realization:** Today had four tasks across three services, and every one of them turned on the same axis: **the object existed, but the wiring was wrong.** The container was running — but had no port mapping. The EKS role didn't exist — and the cluster couldn't be created until it did, with the *right* trust principal. The IAM role existed — but the trust policy had three bugs, one of which might have silently broken it. **In every case, the resource was the easy part; the connections were the whole job.**
>
> And the connection failures came in three flavors that map directly onto the week's running theme:
>
> **Missing wiring** — the container had no `-p` flag. `docker ps` said "running." `docker port` said nothing. The write command succeeded at one layer while the next layer had nothing to work with.
>
> **Wrong wiring** — the EKS cluster role used the correct trust principal shape, but I had to know it was `eks.amazonaws.com` and not `ec2.amazonaws.com`. A role with the wrong principal looks identical to a role with the right one until a service tries to assume it and can't.
>
> **Silently wrong wiring** — `"Sts:AssumeRole"` with a capital S. Valid HCL, valid JSON, possibly accepted by the AWS parser, possibly not. The kind of error that doesn't announce itself and surfaces later as something else's failure.
>
> **The defense is the same as it has been all week: verify with the reader, not the writer.** `docker port` reads the mapping. `get-role` reads the trust policy. `describe-cluster --query` reads the endpoint and Auto Mode settings. **Not the apply success message — the *state*.** The apply tells you the command was accepted; only the describe tells you the result is correct.
>
> Tomorrow is Terraform L1's finish line. Today was the last rehearsal — and the rehearsal covered almost every class of error that the assessment is designed to catch. Missing required arguments. Wrong values in valid syntax. Silent case errors. **The assessment won't ask me to recite commands. It'll ask me to get the wiring right.** Today's four tasks were four different wirings, and all four were fixed by the same discipline: read the error, name the missing link, verify with the reader. If tomorrow's assessment holds that shape, the practice has been proportional.
