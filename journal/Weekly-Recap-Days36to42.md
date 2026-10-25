---

# 📊 Weekly Recap — Days 36–42

[![Week](https://img.shields.io/badge/week-6-blue)](#)
[![Days](https://img.shields.io/badge/days-36--42-green)](#)
[![Status](https://img.shields.io/badge/status-completed%20(Day%2042%20partial)-yellowgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 6: Days 36–42

> **Week 6 pushed Docker from learning to reflex, made IAM trust chains the real subject, and forced the discipline that the task wording — not the intent — is the contract.**

Covered: **Docker (run, cp, commit, Dockerfile, tag), ECS Fargate end-to-end, IAM execution roles and instance profiles, ALB + Target Group AZ coverage, S3 static website, VPC connectivity debugging, KMS encrypt/decrypt, Terraform (native resources vs provisioners, targeted destroy, variable scoping).**

> 🔑 **Theme of the week:** read the task literally, verify with the consumer's reader, and treat every word in the prompt as a flag the grader checks.

---

## 📅 Daily Summary

| Day | DevOps | AWS | Personal |
|---|---|---|---|
| **36** | Docker `nginx:alpine` (fast — L1+L2+L3 muscle memory) | EC2 + ALB + Target Group (`Target.NotInUse`, 4 retries, `SetSubnets` denied) | CloudFormation stack, OpenSearch (failed → retry Day 37) |
| **37** | `docker cp` encrypted file (byte-identical, hash verified) | S3 + IAM role + EC2 (`xfusion-s3-417975622584`, four-piece role chain) | OpenSearch retry, Secrets Manager (`datacenter-secret`) |
| **38** | Docker `busybox:musl` → `busybox:blog` re-tag | ECS Fargate full deployment (execution role missing — 2hr debug) | Terraform IAM attachment (`data` vs `resource`, username vs ARN) |
| **39** | `docker commit` ubuntu_latest → `news:devops` | S3 static website (`AccessControlListNotSupported` — ACLs off) | Terraform L1 Tasks 28 (S3 versioning) & 29 (`null_resource` + `local-exec`) |
| **40** | Apache in `kkloud` container, port 8084 (2-file change) | VPC connectivity fix (`"Attachments": []` — IGW not attached) | Terraform delete EC2 (targeted destroy), delete IAM group |
| **41** | Dockerfile for Apache 5004 (`CMD apache2ctl -D FOREGROUND`) | KMS `datacenter-KMS-Key` — 5 flag errors, then silent failure on `--query` | Terraform delete IAM role (`DeleteConflict`), delete VPC (`DependencyViolation`) |
| **42** | ⏸️ Power outage | ⏸️ Power outage | Terraform S3 upload (`aws_s3_object` + `etag`), VPC with variable `KKE_vpc` |

---

## 🎯 Three Big Themes

### 1. Docker became reflex — the foundation paid off

Every Docker task this week was under 5 minutes: `nginx:alpine` (run flags from L1/L2), `docker cp` (colon decides direction), `docker commit` (snapshot vs tag distinction), Dockerfile authoring (`DEBIAN_FRONTEND`, `CMD` foreground). This is the Week 5 Terraform theme, but stronger — **the foundation tracks have fully earned their keep.**

### 2. IAM trust chains got real — execution role vs instance profile vs task role

The ECS task (Day 38), the S3+EC2 task (Day 37), and the Terraform IAM tasks (Days 38, 40, 41) all lived in the same family. The differences between **execution role** (ECS pulls images) and **task role** (app inside container) and **instance profile** (EC2 wears a role) are now concrete, not abstract.

| Piece | What it does |
|---|---|
| Instance profile | EC2 wears this, not a role directly |
| Execution role | ECS agent uses this to pull from ECR |
| Task role | Application inside the container uses this |
| Trust policy | Must point at `ecs-tasks.amazonaws.com` for ECS — **not** `ec2.amazonaws.com` |

### 3. Task wording is the contract, not the intent

Three separate places this week where the *shape* of the answer hinged on a single phrase:

| Task wording | Correct answer |
|---|---|
| *"using Terraform"* (Day 42) | `aws_s3_object` — native resource |
| *"use the AWS CLI through Terraform"* (Day 39) | `null_resource` + `local-exec` — **opposite** |
| *"variable name `KKE_vpc`"* (Day 42) | `variable "KKE_vpc" { default = "datacenter-vpc" }` — identifier vs value |
| `--tags TagKey=...,TagValue=...` (Day 41) | KMS shape, **not** `--tag-specifications` |

---

## 🔥 Hardest Moments

**ECS execution role (Day 38) — 2 hours of `Running: 0`.** The `ecsTaskExecutionRole` referenced in the task definition didn't exist. The service sat at `Running: 0, Desired: 1` with an empty events array, then finally populated: *"ECS was unable to assume the role."* The fix was 3 commands. The diagnosis was the hard part — the error was hidden by the ECS service's initial silence.

**KMS flag chain (Day 41) — 5 errors in a row.** `--tags-specifications` → `--tag-specifications` → `--tag-specifications` (still wrong) → `--tags TagKey=Name,TagValue=...` (correct). Then `alias/` prefix on the alias. Then `file://` with relative path. Then `fileb://` with relative path. Then `fileb:///root/...` (correct). **And then a success that ran silently wrong** — `--query Encrypted.bin` was an invented field name; the command returned no error, wrote nothing useful, and looked like progress.

**ALB `Target.NotInUse` (Day 36) — 4 retries.** `wait target-in-service` hung for 5+ minutes. The wait command has no default timeout and hides the reason code. The actual diagnostic was `describe-target-health` — which showed `Target.NotInUse`: the EC2 was in `us-east-1b`, the ALB was in `1a` and `1c`. `SetSubnets` was AccessDenied (narrow lab policy). Fix: delete the ALB, recreate with the EC2's subnet.

**Power outage (Day 42).** Lost both 100 Days streaks. KodeKloud doesn't allow catch-up on unpaid tracks. Day 100 shifts Dec 21 → 22; **every other milestone is unchanged** because Terraform, K8, and the project plan don't depend on 100 Days progress.

---

## 🧠 Skills Sharpened

| Area | Growth |
|---|---|
| **Docker** | `cp`, `commit`, Dockerfile authoring, `CMD` foreground, port config in 2 files |
| **ECS / Fargate** | ECR → cluster → task definition → service, execution role wiring, `--health-check-grace-period-seconds` |
| **ALB / Target Groups** | AZ coverage requirement, `Target.NotInUse` diagnostic, SG chaining, `describe-target-health` over `wait` |
| **IAM** | Execution role vs task role vs instance profile, trust policies, four-piece role chain for EC2 |
| **S3** | `BlockPublicAcls`, `BucketOwnerEnforced` (ACL disabled), bucket policies, `aws_s3_object` + `etag` |
| **VPC Networking** | IGW attachment (not just existence), route table association (not just route presence), filtered describes |
| **KMS** | Key creation, alias namespace, base64 ciphertext trap, tag shape |
| **Terraform** | Native resource vs `local-exec`, `-target` on destroy, dependency chains, variable scoping |
| **Verification** | `describe-target-health`, `curl` with the consumer's reader, `diff` on downloaded content, three-view check |

---

## 🏅 Certifications

| Badge | Status |
|---|---|
| 🐧 Jenkins L1 | 100% ✅ (earned Day 29) |
| ⚙️ Ansible L1 | 100% ✅ |
| 🌿 Git L1 | 100% ✅ |
| 🐧 Linux L1 | 86% ✅ |
| 🐳 Docker L1 | 80% ✅ |
| 🔧 Terraform L1 | **In progress** — Task 40 + L1 assessment scheduled for Oct 27 |

**No new certification this week.** Terraform L1 is on pace for Oct 27, which lands in Week 7.

---

## 🎓 Five Lessons That Stuck

1. **Read the task literally — the wording names the expected pattern.** *"Using Terraform"* vs *"using AWS CLI through Terraform"* are opposite correct answers. `--tags TagKey=...` vs `--tag-specifications` differ by service. The prompt is the contract.

2. **Verify with the consumer's reader, not the writer's output.** The KMS task looked correct (`encrypt` returned a `CiphertextBlob`) but the file wasn't loadable via `fileb://`. The grader loads with `fileb://`. Verify with the same reader the grader uses.

3. **A command that returns no error is not evidence it worked.** `--query Encrypted.bin` ran silently, wrote nothing useful, and looked like progress. The dangerous failure mode isn't the loud one — it's the one that didn't announce itself.

4. **`-target` doesn't skip the dependency graph — it limits the scope.** A single `-target` on a resource with children fails with `DeleteConflict` (IAM) or `DependencyViolation` (VPC). Name the whole chain: attachment → role, subnet → VPC.

5. **The tool's vocabulary is finite; the shape of a word doesn't imply it's real.** `aws_instance_delete` looked plausible. `--tags-specifications` looked plausible. `Values=` looked like an ID. Each ran against a tool that said "no such thing." Trust the tool's vocabulary, not the pattern you remember.

---

## 📊 Week in Numbers

| Metric | Count |
|---|---|
| Days completed | 6 full + 1 partial (Day 42) |
| DevOps tasks | 6 |
| AWS tasks | 6 |
| Terraform tasks | 13 |
| Total tasks | 25 |
| Certifications earned | 0 (Terraform L1 in progress) |
| Failed attempts before success | 8+ |
| Silent failures caught | 2 (`--query Encrypted.bin`, `--acl public-read` near-miss) |
| Days with power outage | 1 (Day 42) |
| Debugging sessions over 1 hour | 2 (ECS execution role, KMS flag chain) |

---

## 🎯 Focus for Week 7 (Days 43–49)

* 🔧 **Terraform L1 completion** — Task 40 + L1 assessment (Oct 27)
* ⚙️ **Terraform L2 start** (Oct 28) — VPC/subnet/EC2/SG, then S3 depth, SNS/SQS, IAM deep
* ☁️ **100 Days Cloud/DevOps Day 100 slips to Dec 22** — project window absorbs as extra day
* 🐳 **Container work continues** — Dockerfile patterns, ECR + ECS
* 🔐 **IAM security depth** — permission boundaries, policy conditions, cross-account access
* 📝 **Journal continuation** — daily, even when partial (Day 42's power-outage entry set the template)

---

## 💡 Week 6 Major Realization

> **A command that returns no error is the most dangerous failure mode of all.**
>
> Every loud failure this week — `AccessControlListNotSupported`, `DeleteConflict`, `DependencyViolation`, `Target.NotInUse`, `InvalidVpcId.Malformed` — was a gift. The tool told me exactly where the broken link was. The fix was always trivial once the reason code was read.
>
> The failures that cost hours were the ones that didn't announce themselves. `--query Encrypted.bin` ran cleanly and wrote nothing useful to the wrong file. The KMS `encrypt` returned a valid-looking base64 string that wasn't what the grader would load. The `wait target-in-service` hung without timeout and hid the reason code that would have diagnosed the AZ mismatch in 10 seconds. The `terraform destroy -target` for a single resource exited without error but left the resource undeleted in AWS — because it failed partway and the state cleanup masked the fact.
>
> Week 5 taught: *success of the API call is not correctness of the result.* Week 6 extends it: **success of the API call is not correctness AND is not evidence the file / resource / result is in the shape the next step expects.**
>
> The defense is not "run more commands." It's **run the exact reader the next step will use.** The grader loads `fileb://` — the file must be binary, not base64. The next task filters by `tag:Name` — the tag must exist, not just the resource. The destroy must produce both an empty `terraform state list` **and** an empty `aws describe-*` — not one and not the other. Two views, both empty, both agree. **Anything short of that is assumption dressed as verification.**

---

<div align="center">

## ✅ Overall: 🟢 Week 6 — Days 36–42 Completed (Day 42 partial)

**42/100 Days Complete**

</div>

---

