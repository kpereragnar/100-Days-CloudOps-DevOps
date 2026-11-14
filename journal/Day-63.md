Here is the journal entry for today. 

Since we transitioned back to Terraform today, this entry captures the K8 wrap-up and the return to Infrastructure as Code.

---

# CloudOps / DevOps Journal

## Day 63 — 14 November 2026

**Challenges:** 100 Days DevOps & Terraform L2

> **Context:** Wrapped up a Kubernetes Secret task for 100 Days DevOps, then successfully transitioned back to the Terraform L2 track. Diagnosed and fixed several Terraform syntax and attribute errors.

---

## 1. 100 Days DevOps — Kubernetes Secret & Pod

**Task:** Create a generic secret `news` from the file `/opt/news.txt`. Create a pod `secret-nautilus` that mounts the secret at `/opt/cluster`.

**The Fix:**
```bash
# Create the secret (key is the filename, value is the file content)
kubectl create secret generic news --from-file=/opt/news.txt

# Pod manifest
cat > /tmp/secret-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secret-nautilus
spec:
  containers:
    - name: secret-container-nautilus
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "sleep infinity"]
      volumeMounts:
        - name: secret-volume
          mountPath: /opt/cluster
          readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: news
EOF

kubectl apply -f /tmp/secret-pod.yaml
```

**Verification:**
```bash
kubectl exec secret-nautilus -- cat /opt/cluster/news.txt
# → outputs the password from the original file
```

### Key Learning
**`--from-file` maps the filename to the key.** When you do `--from-file=/opt/news.txt`, the key in the Secret becomes `news.txt`. When mounted as a volume, Kubernetes creates a file named `news.txt` inside the mount directory. If you use `--from-literal=password=123`, the file created in the mount would be named `password`. 

**`readOnly: true`** is best practice for secrets. The volume is a `tmpfs` in memory, and `readOnly` prevents any container process from trying to modify the license information.

---

## 2. Terraform — Syntax Troubleshooting (`variables` vs `outputs`)

**Issue:** A syntax error was submitted regarding variables and outputs:
```hcl
variable KKE_ami_id {
   variable = var.aws_ami_from_instance.ec2_ami.ami_id
}

output "KKE_new_instance_id" {
    value = var.aws_instance.ec2_new.instance_id
}
```

**The Fix:** 
1. **Variables cannot be assigned resource attributes.** A `variable` block is for *inputting* values into Terraform (from `tfvars`, CLI, or defaults). It cannot hold a reference to an AWS resource.
2. **Resource references do not use `var.`.** The `var.` prefix is strictly for input variables. To reference an AWS resource, you use its specific address (e.g., `aws_instance.ec2_new.id`).

**Correct Syntax:**
```hcl
output "KKE_new_instance_id" {
  value = aws_instance.ec2_new.id
}

output "KKE_ami_id" {
  value = aws_ami_from_instance.ec2_ami.id
}
```

### Key Learning
**The Golden Rule of Terraform References:**
- `var.name` = References a variable defined in `variables.tf`.
- `aws_resource.name.attribute` = References a resource managed by Terraform.

---

## 3. Terraform L2 — AMI Creation and New Instance Deployment

**Task:** Write a Terraform configuration to create an EC2 instance, create an AMI from that instance, and then launch a second EC2 instance using that new AMI.

**The Fix:**
The initial code had wrong attribute names. We corrected them to use the standard `.id` attribute exported by the AWS provider.

```hcl
# 1. Provision the original instance
resource "aws_instance" "ec2" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["sg-09c09df2f3e2c8685"]
  tags = { Name = "datacenter-ec2" }
}

# 2. Create the AMI from the instance
resource "aws_ami_from_instance" "ec2_ami" {
  source_instance_id = aws_instance.ec2.id   # Fixed: uses .id
  
  tags = { Name = "datacenter-ec2-ami" }
}

# 3. Provision the new instance using the new AMI
resource "aws_instance" "ec2_new" {
  ami           = aws_ami_from_instance.ec2_ami.id   # Fixed: uses .id
  instance_type = "t2.micro"
  vpc_security_group_ids = ["sg-09c09df2f3e2c8685"]
  tags = { Name = "datacenter-ec2-new" }
}
```

### Key Learning
**Terraform handles dependencies automatically through references.** We didn't need to use `depends_on`. Because `aws_ami_from_instance` references `aws_instance.ec2.id`, and `aws_instance.ec2_new` references `aws_ami_from_instance.ec2_ami.id`, Terraform builds a dependency graph:
`Instance A` → `AMI` → `Instance B`.

**Attribute naming in the AWS provider is predictable.** Unless a resource explicitly exports a custom name (like `arn`), its primary ID is almost always accessed via `.id`. There is no `.instance_id` or `.ami_id` attribute in the standard AWS provider.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 – Nov 13 | ✅ Completed |
| **Terraform L2** | Nov 14 | 🟢 Resumed |
| **100 Days DevOps** | Ongoing | K8 Block |
| **Codomax Internship** | Nov 8 | Module 05 (Lambda) Completed |

---

## Key Takeaways
- 🐳 **`kubectl create secret generic --from-file`** uses the filename as the Secret key.
- 🐳 **Mounting secrets as volumes** creates a file for each key in the mount path.
- 🔧 **Variables are for inputs only.** Never try to assign a resource attribute to a `variable` block.
- 🔧 **Resource references drop the `var.` prefix.** `var.` is for variables, not resources.
- 🔧 **Terraform's `.id` attribute** is the primary identifier for AWS resources in the provider.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — K8 Secrets | 🟢 Completed |
| Terraform L2 — Syntax fixes | 🟢 Completed |
| Terraform L2 — AMI & New EC2 | 🟢 Completed |

**Overall: 🟢 Day 63/100 — Completed · Terraform L2 Resumed**

> **Realization:** Moving from Kubernetes back to Terraform was a good reset. K8 forces you to think about operational lifecycles and state (Pods, Volumes, Services). Terraform forces you to think about declarative dependencies (Resource A creates ID, which Resource B needs). Both are Infrastructure as Code, but they solve different problems. The syntax errors today were a good reminder that in Terraform, you are building a graph of dependencies, not just writing scripts. If the reference is wrong, the graph breaks.
