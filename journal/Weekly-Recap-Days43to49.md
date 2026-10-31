# 📊 Weekly Recap — Days 43–49

[![Week](https://img.shields.io/badge/week-7-blue)](#)
[![Days](https://img.shields.io/badge/days-43--49-green)](#)
[![Status](https://img.shields.io/badge/status-completed%20(Day%2049%20partial)-yellowgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 7: Days 43–49

> **Week 7 closed Terraform L1 at 75%, opened L2, and produced the journal's single worst debugging chain — five cascading failures from one missing `EOF`, ending in `Runtime.ImportModuleError`.** The plan absorbed two interruptions (an AFIT day, a 12-hour Bincom assessment) without moving a single downstream milestone.

Covered: **Docker macvlan, `docker commit`, container port immutability, Docker Compose (httpd, php+mariadb), Dockerfile context paths; DynamoDB table schema, EKS private endpoint + Auto Mode, NAT Gateway, Launch Template + ASG + ALB + target tracking, Lambda + S3 + DynamoDB event-driven copy, CloudFormation Lambda; Terraform `-replace`, `count`, EIP association, IAM role/policy/user, VPC+subnet, private VPC+EC2, S3 with ACL chain.**

> 🔑 **Theme of the week:** the tool's vocabulary is narrower than the assumption of it. Every failure named the exact shape the tool wanted — the fix was one word or one character away.

---

## 📅 Daily Summary

| Day | DevOps | AWS | Terraform |
|---|---|---|---|
| **43** | Docker network `media` (macvlan) | DynamoDB table + 2 items (`AttributeDefinitions` vs `KeySchema`) | SG `KKE_sg` + EIP `KKE_eip` (missing `data` source; unquoted label) |
| **44** | nginx container `ecommerce` (missing `-p` → recreate) | EKS `xfusion-eks` private endpoint (Auto Mode 3-part, role missing) | IAM user variable, IAM role variable (missing `assume_role_policy`, then 3 trust-policy bugs) |
| **45** | httpd via Compose (`container_name` ≠ service name) | Launch Template + ASG + ALB (ScaleInCooldown, UserData base64) | 🏆 **Terraform L1 Assessment — 75%, 105/110 min** |
| **46** | Dockerfile fix (context-relative paths) | NAT Gateway for private EC2 (new RT, not main) | **L2 Task 1** (VPC+subnet `depends_on`), **Task 2** (private VPC+EC2, 6 errors) |
| **47** | Compose php_web + mysql_web (MYSQL_ROOT_PASSWORD) | Lambda + S3 + DynamoDB copy — **5 failures, 1 root cause** | ⏸️ **Not attempted** (AFIT day) |
| **48** | — | — | **3-task recovery sprint:** `-replace`, `count` (6 errors), EIP association |
| **49** | **First K8 pod** `pod-httpd` | Lambda via CloudFormation (ZipFile inline, ManagedPolicyArns) | ⏸️ Paused — **Bincom assessment: 12h write, not yet run** |

---

## 🎯 Three Big Themes

### 1. Terraform L1 closed at 75% — and the assessment was the real test

**105 of 110 minutes, 10 questions, 3 likely misses.** Q2 (path trap), Q7 (ACL chain), Q10 (CIDR precision). **Every miss was a shape the journal had documented** — `${path.module}` vs `/home/bob` (Day 41's `fileb://` vs `fileb:///`), 4-resource ACL requirement (Day 39's `AccessControlListNotSupported`), `192.168.0.0/24` vs `/16` habit (Day 44's `iampolciy` typo).

**The assessment tested iteration speed, not knowledge.** Ten single-resource blocks took 105 minutes because the write → plan → read error → edit → re-plan loop ran ten times. **The loop is the skill.**

### 2. The L1 → L2 structural shift

**L1's 2 files became L2's 4 files.**

| | L1 | L2 |
|---|---|---|
| Files | `main.tf` + `variables.tf` | `main.tf` + `variables.tf` + `outputs.tf` + `terraform.tfvars` |
| Variables | `default = "..."` inline | `type = string` with no default — from tfvars |
| Outputs | Optional | **Explicit deliverables** |
| `depends_on` | Not tested | Explicit requirement |

**Resource blocks unchanged.** `aws_vpc`, `aws_instance`, `aws_eip` — same primitives. **What changed is organization.** L1 tested whether you could write a resource; L2 tests whether you can structure a project.

### 3. The plan absorbed two interruptions without moving a milestone

**Day 47's AFIT day** — Terraform missed. Day 48's 3-task sprint recovered it. **Finish Nov 12 unchanged, coins unchanged.** **Day 49's Bincom assessment** — 12 hours of writing, no Terraform task. **K8 L1 takes over from Nov 1, Terraform resumes Nov 8. Both land Nov 22.**

**Same pattern as Day 42's power outage.** The plan has slack because the "2/day through X" windows are adjustable. **The only thing that moves the finish line is a dependency break, and neither interruption caused one.**

---

## 🔥 Hardest Moments

**Terraform L1 Assessment — 105 minutes, 75%.** Ten tasks. The time went to the loop, not the knowledge. **The `terraform plan` read-error-edit-re-plan cycle ran ten times.** Every question was a variation of the same shape — `<type>` + required args + tags. What changed per question was which required arguments the resource needed.

**Day 47 Lambda — five failures, one root cause.** The heredoc without closing `EOF` swallowed the `--policy-arn` line, the `create-role` step never ran, the role didn't exist, `$ROLE_ARN` was empty, `zip -f` didn't create the archive, and the file inside the zip was `lambda-function.py` (hyphen) instead of `lambda_function.py` (underscore). **Six different error messages, one missing `EOF`.** The real failure was `Runtime.ImportModuleError: No module named 'lambda_function'` — visible only in the Lambda log, hidden from every CLI command.

**Day 46 L2 Task 2 — 6 errors on first independent attempt.** `aws_ec2` → `aws_instance`. Missing `vpc_id` on subnet. `assign_ipv4_address_on_creation` → `map_public_ip_on_launch`. Bare output assignments. Unquoted type. Missing SG. **All same error classes as the whole week.** The plan caught every one.

**Day 49 Bincom — 12 hours writing, not yet run.** Full PrestaShop on AWS. 8 `.tf` files, 2 user-data scripts, 2 CloudWatch agent configs. VPC, two t3.micro Ubuntu 24.04, IMDSv2, SSM instead of SSH, IAM instance profile, CloudWatch log groups. **Validated: `terraform fmt`, `validate`, `plan` (15 resources), `bash -n`, `json.tool`. Nothing applied.** The code is the artifact; the deployment is proof.

---

## 🧠 Skills Sharpened

| Area | Growth |
|---|---|
| **Docker** | macvlan network, `commit` vs `tag`, port immutability, Compose `container_name`, multi-service stacks, context-relative COPY |
| **AWS** | DynamoDB schema, EKS private endpoint + Auto Mode, NAT Gateway chain, Launch Template + ASG + ALB, Lambda + S3 + DynamoDB, CloudFormation Lambda |
| **Terraform** | `-replace`, `count`, `[*]` splat, EIP association, `terraform.tfvars` + `outputs.tf`, IAM role/policy trust policies |
| **Debugging** | Diagnostic ladder for silent failures, log-vs-CLI separation, JSON validation before use |
| **CloudFormation** | `ZipFile` inline, `ManagedPolicyArns` vs inline `Policies`, `CAPABILITY_NAMED_IAM`, `!GetAtt` dependencies |
| **K8s** | First pod — labels, containers, `kubectl describe` |
| **IaC discipline** | 12-hour write, validated statically, not yet deployed |

---

## 🏅 Certifications

| Badge | Status |
|---|---|
| 🐧 Jenkins L1 | 100% ✅ |
| ⚙️ Ansible L1 | 100% ✅ |
| 🌿 Git L1 | 100% ✅ |
| 🐧 Linux L1 | 86% ✅ |
| 🐳 Docker L1 | 80% ✅ |
| **🔧 Terraform L1** | **75% ✅ — earned this week** |
| 🐳 Docker L2 | 100% ✅ |
| ⚙️ Ansible L2 | 100% ✅ |

**Terraform L1 completed Day 45.** L2 in progress at 5/20. K8 L1 starts Nov 1.

---

## 🎓 Five Lessons That Stuck

1. **The tool's vocabulary is narrower than your assumption of it.** `aws_ec2` → `aws_instance`. `assign_ipv4_address_on_creation` → `map_public_ip_on_launch`. `lambda-function.py` → `lambda_function.py`. `domain = "vpc"` not `vpc = true`. **Each is a one-word fix after an error that named the exact gap.**

2. **Silent failures are the dangerous ones.** ECS `Running: 0` with empty events for 90 seconds. Lambda `storedBytes: 0` on the log stream. Empty `$ROLE_ARN` producing a completely different error. **The command that doesn't error is the one that costs hours.**

3. **Heredocs need their closing `EOF`.** A missing `EOF` swallowed the `create-role` command, cascaded into `EntityAlreadyExists` on the policy, left `$ROLE_ARN` empty, and produced `Value '' at 'role' failed to satisfy constraint`. **One missing line, five errors, an hour lost.** Validate JSON files with `python3 -m json.tool` immediately after creating them.

4. **The diagnostic ladder isolates the layer.** Trigger → file → invoked → code loaded → wrote. Whichever check is first to fail is the real problem. **Everything below it is echo.** Same discipline as Day 40's three-layer internet check and Day 46's four-layer VPC check.

5. **The plan absorbs interruptions without moving the finish line.** Day 47's AFIT day → 3-task sprint on Day 48 → recovered. Day 49's 12-hour assessment → plan change to K8 first → both tracks land Nov 22. **The only thing that moves the finish line is a dependency break. Neither happened.**

---

## 📊 Week in Numbers

| Metric | Count |
|---|---|
| Days completed | 6 full + 1 partial (Day 49) |
| Terraform L1 assessment | **75% · 105/110 min** |
| Terraform L2 tasks | **5/20** |
| 100 Days tasks | 13 (DevOps 7 + Cloud 6) |
| Certifications earned | 1 (Terraform L1) |
| Documents written | 1 (Bincom assessment — 12h, ~1,800 lines) |
| Interruptions absorbed | 2 (AFIT day, Bincom day) |
| Plan changes | 2 (coin model, K8 first) |
| Debugging chains resolved | 2 (Lambda 5-failure chain, L2 Task 2 6-error chain) |
| Silent failures caught | 3 (ECS role, Lambda handler, EIP empty ARN) |

---

## 🎯 Focus for Week 8 (Days 50–56)

- 🐳 **K8 L1 at 2/day from Nov 1** — 14 tasks, finish Nov 7
- 🔧 **Terraform L2 resumes Nov 8 at 1/day free** — 15 tasks remaining, finish Nov 22
- ☁️ **100 Days K8 block continues** — Days 50–56 are all K8
- 🏗️ **Bincom assessment deploy** — the code is written; the deployment is the proof
- 📝 **Daily journal** — 3 L2 tasks, 1 K8 task, 1 journal entry minimum per day

---

## 💡 Week 7 Major Realization

> **The assessment tested iteration speed, not knowledge. The project tests decision quality, not execution.**
>
> Ten single-resource Terraform questions took 105 minutes because the loop ran ten times. **The loops didn't stop when the plan succeeded — they continued when the describe showed something unexpected, when the output name was lowercase, when the CIDR was off by a mask.** Every "pass" in the assessment was a loop that terminated cleanly; every miss was a loop that terminated on the wrong assumption.
>
> The Bincom assessment is the same lesson at a different scale. **Twelve hours of writing that hasn't run yet is twelve hours of decisions that can't be validated by reality.** The VPC, the 11 PHP extensions, the CloudWatch configs, the SSM choice — every one is a decision that has to be reasoned through, not tested. **The `terraform plan` is the closest thing to validation the project gets until it runs.** And that's the difference from the labs: **in the labs, the tool tells you what's missing in seconds. In the project, you have to be the tool.**
>
> **Same shape across the week:** the plan absorbs interruptions without moving the finish line; the loop runs until the describe agrees with the write; the tool's rule is narrower than the assumption of it. **Three expressions of one discipline.** Day 45's assessment, Day 46's L2 Task 2, Day 47's Lambda chain, Day 48's recovery sprint, Day 49's 12-hour write — **all five are the loop, at different scopes.** That's the week's real output: not the certification, not the projects, but the reflex that keeps the loop running until the state matches the intent.

---

<div align="center">

## ✅ Overall: 🟢 Week 7 — Days 43–49 Completed (Day 49 partial)

**Terraform L1 Certified · L2 at 5/20 · K8 block entered**

</div>

