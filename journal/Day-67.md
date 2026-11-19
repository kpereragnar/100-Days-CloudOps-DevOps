# CloudOps / DevOps Journal

## Day 67 — 18 November 2026

**Challenges:** Terraform L2

> **Context:** A deep dive into IAM roles and instance profiles. Reviewed my initial skeleton for an EC2 + S3 + IAM task, identified multiple missing arguments and structural gaps, and implemented the complete working configuration.

---

## 1. Terraform L2 — EC2, S3, and IAM Role

**Task:** Create an EC2 instance (`datacenter-ec2`), an S3 bucket (`datacenter-logs-242847739`), an IAM role (`datacenter-role`), and a policy (`datacenter-access-policy`) allowing `s3:PutObject`. Attach the role to the EC2 instance. Use `variables.tf`, `terraform.tfvars`, `outputs.tf`, and `data.tf` for the AMI lookup.

### My Initial Attempt (Skeleton)

I got the variables and tfvars right. But my `main.tf` was just a skeleton:

```hcl
resource "aws_instance" "ec" {
    ami = 
    tag = { Name = var.KKE_INSTANCE_NAME }  # tag should be tags
}

resource "aws_s3_bucket_acl" {  # missing second label
    bucket = aws_s3_bucket.bucket.id
    acl = "private"
}

resource "aws_iam_role" "role" {
    name = var.KKE_ROLE_NAME
    # missing assume_role_policy
}

resource "aws_iam_policy" "policy" {
    name = var.KKE_POLICY_NAME
    policy =  # missing policy document
}
```

**Rating:** 2/10 for `main.tf`. Variables and tfvars were 9/10.

### The Complete Fix

**The `data.tf` file** (first time using `data` for an AMI):
```hcl
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**The `main.tf`** (complete with all 8 resources):
```hcl
# 1. S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.KKE_BUCKET_NAME
}

# 2. Ownership Controls (needed for ACLs on modern buckets)
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 3. ACL
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket     = aws_s3_bucket.bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]
}

# 4. IAM Policy
resource "aws_iam_policy" "policy" {
  name = var.KKE_POLICY_NAME
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.bucket.arn}/*"
    }]
  })
}

# 5. IAM Role
resource "aws_iam_role" "role" {
  name = var.KKE_ROLE_NAME
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 6. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# 7. Instance Profile
resource "aws_iam_instance_profile" "profile" {
  name = "${var.KKE_ROLE_NAME}-profile"
  role = aws_iam_role.role.name
}

# 8. EC2 Instance
resource "aws_instance" "ec" {
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.profile.name
  tags = { Name = var.KKE_INSTANCE_NAME }
}
```

### Key Learning

**1. `data` vs `resource`:** 
- `data "aws_ami"` **reads** an existing AMI. I don't own it; I just look it up. 
- `resource "aws_instance"` **creates** something new. 
- Same rule as Day 38 (`data "aws_iam_user"`) and Day 43 (`data "aws_vpc"`).

**2. EC2 cannot wear an IAM role directly.** 
It wears an **instance profile**. The chain is:
`Policy` → `Role` → `Instance Profile` → `EC2 Instance`.

If you attach the role but forget the profile, the instance has no credentials. If you attach the profile but forget the policy, the profile exists but the role has no permissions. All four pieces are required.

**3. The trust policy must point at `ec2.amazonaws.com`.**
Not `lambda`, not `ecs-tasks`. This is the 4th time this lesson has appeared in the journal (Day 37, 38, 44, 64). Each service has exactly one correct principal.

**4. `tag` vs `tags`.** 
Terraform uses `tags` (a map) for tagging. `tag` (singular) doesn't exist. Same class of error as `assign_ipv4_address_on_creation` vs `map_public_ip_on_launch` from Day 46.

**5. Resource blocks need two labels.**
`resource "aws_s3_bucket_acl" { ... }` is invalid. It needs `resource "aws_s3_bucket_acl" "name" { ... }`. Terraform will reject the missing label at parse time.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 5 days |

---

## Key Takeaways
- 🔧 **`data` blocks read, `resource` blocks create.** Never mix them up.
- 🔧 **EC2 needs an instance profile,** not a role directly.
- 🔧 **Trust policy points to `ec2.amazonaws.com`.**
- 🔧 **Resource blocks require two labels** — type and name.
- 🔧 **Use `tags` (map),** not `tag`.

---

## Day Status
| Area | Status |
|---|---|
| Terraform L2 — EC2 + S3 + IAM | 🟢 Completed |

**Overall: 🟢 Day 67/100 — Completed**

> **Realization:** My initial skeleton was technically "on the right track" — the resource types were correct, the variables were correct, and the structure was correct. But a skeleton without required arguments is not infrastructure; it's a shopping list. The real work isn't knowing which resources to use — it's knowing which arguments make those resources actually function. The EC2 doesn't just *exist* with a role; it exists *because* the profile exists, which exists *because* the role exists, which exists *because* the trust policy allows EC2 to assume it. Every arrow in that chain is a required argument. Miss one and the whole chain collapses.
