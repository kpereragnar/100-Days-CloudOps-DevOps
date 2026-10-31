# CloudOps / DevOps Journal

## Day 49 — 31 October 2026

**Challenges:** 100 Days of DevOps (K8 block), 100 Days of Cloud, and the Bincom ICT Recruitment Assessment

> **Context:** K8 L1 paused at 5/20 Terraform L2. Plan switched — K8 L1 to 2/day from Nov 1, Terraform L2 resumes Nov 8. Both land Nov 22. Today was largely consumed by the Bincom assessment — 12 hours of writing, not yet run.

---

## 1. 100 Days of DevOps — First K8 Pod

**Task:** Pod `pod-httpd`, image `httpd:latest`, label `app=httpd_app`, container `httpd-container`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-httpd
  labels:
    app: httpd_app
spec:
  containers:
    - name: httpd-container
      image: httpd:latest
```

```bash
kubectl apply -f /tmp/pod.yaml
kubectl get pod pod-httpd --show-labels
kubectl describe pod pod-httpd | grep -E "Image:|Container:"
```

**Verified:** `Running`, label `app=httpd_app`, image `httpd:latest`, container `httpd-container`.

### Key Learning

**Labels live on the pod; the container has no labels.** `metadata.labels` at the pod level is what selectors match — that's the `app=httpd_app` requirement. The container's identity is only `name`, inside `spec.containers`.

**`httpd:latest` — the `:latest` tag must be explicit.** The task says "Ensure to specify the tag as httpd:latest" — because `image: httpd` defaults to `latest` but **the grader checks the literal string in the manifest**. Same discipline as every "exact name" requirement this week.

**This was the first K8 task in the journal.** 100 Days has entered the K8 block. The next ~19 days are K8. That's why the plan shifted — the daily track and the L1 track now overlap almost entirely.

---

## 2. 100 Days of Cloud — Lambda via CloudFormation

**Task:** Template `/root/devops-lambda.yml`, stack `devops-lambda-app`. Lambda `devops-lambda` (128 MB, 10s, python), prints `Welcome to KKE AWS Labs!`, returns `statusCode: 200`. Role `lambda_execution_role`.

**Template:**

```yaml
Resources:
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: lambda_execution_role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal: { Service: lambda.amazonaws.com }
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  DevopsLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: devops-lambda
      Runtime: python3.11
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      MemorySize: 128
      Timeout: 10
      Code:
        ZipFile: |
          import json
          def lambda_handler(event, context):
              body = 'Welcome to KKE AWS Labs!'
              print(body)
              return {'statusCode': 200, 'body': body}
```

**Commands:**

```bash
# Cleanup prior role if exists (from earlier Lambda task)
aws cloudformation delete-stack --stack-name devops-lambda-app 2>/dev/null
aws cloudformation wait stack-delete-complete --stack-name devops-lambda-app 2>/dev/null

for arn in $(aws iam list-attached-role-policies --role-name lambda_execution_role --query "AttachedPolicies[].PolicyArn" --output text 2>/dev/null); do
  aws iam detach-role-policy --role-name lambda_execution_role --policy-arn "$arn"
done
aws iam delete-role --role-name lambda_execution_role 2>/dev/null || true

# Deploy
aws cloudformation create-stack \
  --stack-name devops-lambda-app \
  --template-body file:///root/devops-lambda.yml \
  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation wait stack-create-complete --stack-name devops-lambda-app

# Invoke
aws lambda invoke --function-name devops-lambda --log-type Tail \
  --query "LogResult" --output text /tmp/r.json | base64 -d | grep Welcome
cat /tmp/r.json
```

**Expected final output:**

```json
{"statusCode": 200, "body": "Welcome to KKE AWS Labs!"}
```

### Key Learning

**`ZipFile` inline eliminates the Day 47 problem.** No zip file on disk, no `fileb://` path, no hyphen-vs-underscore confusion. CloudFormation wraps inline code as `index.py` — the module name is guaranteed. **Handler `index.lambda_handler` matches.**

**`ManagedPolicyArns` avoids `iam:PutRolePolicy`.** Same fix as Day 49's earlier CloudFormation attempt. **No inline `Policies:` block = no `PutRolePolicy` call = no AccessDenied.**

**`!GetAtt` creates the dependency.** The Lambda gets the role ARN only after the role exists. **The reference is the dependency** — same pattern as Day 46's subnet depending on VPC.

**No custom policy needed** — the function only prints and returns. `AWSLambdaBasicExecutionRole` is the minimum, and the minimum is enough.

---

## 3. Bincom ICT Recruitment Assessment — PrestaShop on AWS

**Task:** Deploy PrestaShop on AWS with web and database on separate EC2 instances. Terraform-managed, Free Tier conscious, security controls, monitoring.

### What I built — 12 hours of writing, not yet run

**Project structure:**

```
internships/bincom/prestashop-aws-deployment/
├── terraform/          # 8 .tf files
├── user-data/          # web-server.sh, database-server.sh
├── docs/
└── README.md
```

**Terraform modules written:**

| File | Contents |
|---|---|
| `providers.tf` | AWS provider, region |
| `variables.tf` | Region, DB name/user/password (sensitive), admin password |
| `vpc.tf` | VPC, public subnet, IGW, route table, association |
| `security-groups.tf` | Web SG (80, 443 from internet; no SSH), DB SG (3306 from web SG only) |
| `ec2.tf` | Two t3.micro Ubuntu 24.04 instances, gp3 encrypted root volumes, IMDSv2 enforced |
| `iam.tf` | Instance profile with `AmazonSSMManagedInstanceCore` + `CloudWatchAgentServerPolicy` |
| `cloudwatch.tf` | Two log groups (7-day retention) |
| `outputs.tf` | Public IP/DNS, private IP, PrestaShop URL |

**User-data scripts written:**

- `web-server.sh` — Apache, PHP with 11 extensions (curl, gd, intl, mbstring, mysql, soap, xml, zip, bcmath, opcache), modules (rewrite, headers, expires, deflate), PHP memory and upload limits, custom vhost, custom HTML portfolio page branded **KPERE RAGNAR** (introduces me as Samuel Asukwo Daniel, highlights AWS/DevOps/cybersecurity/Linux/IaC interests), permissions, service checks
- `database-server.sh` — MariaDB, IMDSv2 private IP retrieval, error log directory, listen on private IP, port 3306, utf8mb4, service verification

**CloudWatch agent configs:**

- Web: Apache access/error logs, memory, disk
- DB: MariaDB error logs, memory, disk

**Validation done:**

```bash
terraform fmt
terraform validate
terraform plan          # → 15 resources to create

python3 -m json.tool web-cloudwatch.json
python3 -m json.tool database-cloudwatch.json

bash -n web-server.sh
bash -n database-server.sh
```

All passed. **15 resources ready — but nothing applied.**

### Key design decisions

**Why Terraform over Console** — reproducibility, version control, documented infrastructure. The reviewer can read the code and run `terraform apply` themselves.

**Why SSM Session Manager instead of SSH** — my ISP public IP changes constantly. SSH rules would need updating every session. SSM has no inbound SSH at all — access goes through the AWS control plane, authenticated by IAM. **The security group's port 22 is not open on either instance.**

**Why both instances in the public subnet** — a NAT Gateway is $32/month, not Free Tier friendly. The DB is still effectively private because its security group only accepts 3306 from the web SG. **The isolation is at the security group layer, not the network layer.** Not ideal for production, defensible for a Free Tier assessment.

**Why `sensitive = true` on passwords** — masks in CLI output. **I noted in the doc that this doesn't encrypt state.** Terraform state files must be protected and gitignored. The `.gitignore` covers state files, tfvars, .env, SSH keys, AWS credentials.

**Why a custom portfolio page** — the web IP is immediately useful during testing, not a generic Apache welcome. **The page is itself a demonstration** — it introduces the project, the stack, and the engineer.

### Current status

- ✅ Code written (all files)
- ✅ Static validation passed
- ✅ Terraform plan shows 15 resources
- ⬜ **Nothing applied yet**
- ⬜ Instances not provisioned
- ⬜ PrestaShop not installed
- ⬜ Portfolio page not live
- ⬜ DB user not created
- ⬜ Screenshots not captured

### Key Learning

**12 hours to write, 10 minutes to run.** That ratio is normal for infrastructure-as-code, and it's the opposite of console clicking. Every hour spent on the user-data scripts, the CloudWatch configs, the security group rules — **is an hour saved on every future deployment.** The cost is upfront; the benefit compounds.

**The reviewer's test is the plan, not just the deploy.** A well-structured 15-resource plan that validates cleanly **demonstrates more skill than a working console setup**. The code is the artifact. The deployment is the proof.

**`sensitive = true` on a variable masks the output, not the state.** Same class as Day 44's `jsonencode` protecting against syntax errors but not wrong values — **the flag does less than the name suggests.** Read the docs for what a safety feature actually does, not what its name implies.

**`bash -n` and `python3 -m json.tool` are the cheapest validation that exists.** Both run in under a second. Both catch the class of error that would otherwise fail at instance boot — ten minutes after `apply`, five minutes into a wait, when the error surfaces only in cloud-init logs. **Cheap validation before expensive execution** — same discipline as `terraform validate` before `plan`, and `terraform plan` before `apply`.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| 100 Days Day 100 | 22 Dec | On track |
| **K8 L1** | Nov 1 → Nov 7 (planned) | Starting tomorrow at 2/day |
| **Terraform L2** | 5/20 · resumes **Nov 8** | Both done Nov 22 |
| Projects | Nov 22 | On track |
| **Bincom assessment** | **Written, not deployed** | Deploy next session |

**Plan change:** Terraform L2 pauses at 5/20. K8 L1 takes the extra-track slot from Nov 1. Terraform resumes Nov 8 at 1/day free. Both tracks land Nov 22, matching the project start.

---

## Key Takeaways

- 🐳 **Pod labels live at `metadata.labels`, not on the container.** The container's identity is only `name`.
- 🐳 **`:latest` must be explicit** — the grader checks the literal string, not the default behavior.
- ☁️ **`ZipFile` inline eliminates the zip file entirely** — no path, no handler-name mismatch, no `fileb://` confusion.
- ☁️ **`ManagedPolicyArns` avoids `iam:PutRolePolicy`** — only `AttachRolePolicy` is needed, and it's allowed.
- ☁️ **`!GetAtt` is the dependency.** The Lambda can't exist before the role does.
- 🏗️ **12 hours writing, 10 minutes running** — the ratio is normal for IaC. The reviewer's test is the plan, not just the deployment.
- 🏗️ **SSM Session Manager closes port 22 entirely** — the security group doesn't allow SSH. Access goes through IAM.
- 🏗️ **Both instances in public subnet, DB protected by SG** — NAT Gateway isn't Free Tier. Defensible for the assessment; document the trade-off.
- 🏗️ **`sensitive = true` masks output, not state.** State files and tfvars must be gitignored separately.
- 🏗️ **`bash -n` and `python3 -m json.tool` are second-long validation.** Cheapest possible check before expensive execution.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — K8 pod | 🟢 Completed |
| 100 Days Cloud — Lambda via CloudFormation | 🟢 Completed |
| **Bincom assessment — PrestaShop project** | 🟡 **Written, validated, not yet deployed** |

**Overall: 🟡 Day 49/100 — Partial (assessment code complete, deployment pending)**

> **Realization:** 12 hours of writing that hasn't run yet is the most honest form of infrastructure engineering. **The code is the artifact. The deployment is proof.** Everything in the assessment — the VPC, the two instances, the 11 PHP extensions, the CloudWatch agent configs, the security group rules, the SSM choice, the gitignore for state files — is a decision that had to be made **before** anything could be validated by reality. That's the difference from the KodeKloud labs. In the labs, `terraform plan` told me what was missing within seconds. Here, every decision had to be reasoned through from first principles, and the reward is that the plan shows 15 resources cleanly and nothing has to be undone.
>
> The other thing: **the plan change for K8 L1 is not a reversal — it's a response to the context.** 100 Days entered K8 this week. Terraform L2 pauses at 5/20 for seven days. Both tracks land Nov 22. **Same discipline as the whole week: the plan absorbs the context change without breaking the finish line.** Day 47's missed day absorbed the AFIT constraint. Day 48 recovered it. Day 49 absorbs the Bincom assessment. **The plan that keeps absorbing interruptions without moving the finish line is the plan that survives.**
