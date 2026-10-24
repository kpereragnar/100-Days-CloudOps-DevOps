# CloudOps / DevOps Journal

## Day 41 — 23 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Custom Dockerfile for Apache on Port 5004 — `/opt/docker/Dockerfile` on App Server 1

I was tasked with:

1. Create a Dockerfile at `/opt/docker/Dockerfile` (capital D, no extension) on App Server 1
2. Use `ubuntu:24.04` as the base image
3. Install `apache2` and configure it to work on port `5004`
4. Do not modify other Apache settings (document root, modules, etc.)

### What I Did

**Step 1 — SSH into App Server 1 and created the working directory:**

```bash
ssh banner@stapp01
sudo su -
mkdir -p /opt/docker
```

**Step 2 — Wrote the Dockerfile:**

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y apache2 && \
    sed -i 's/^Listen 80$/Listen 5004/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:5004>/' /etc/apache2/sites-available/000-default.conf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 5004

CMD ["apache2ctl", "-D", "FOREGROUND"]
```

**Step 3 — Built and verified:**

```bash
cd /opt/docker
docker build -t apache-custom:5004 .
docker run -d --name apache-test -p 5004:5004 apache-custom:5004
curl -I http://localhost:5004
```

Expected: `HTTP/1.1 200 OK` with the default Apache2 Ubuntu page.

### Key Learning

**Changing the Apache port is a two-file operation inside a container too.** `ports.conf` controls where Apache **binds** — it opens the socket on 5004. `sites-enabled/000-default.conf` controls which vhost **answers** on that socket. Change only one and you get a listening port that serves nothing (or falls back unpredictably across Apache versions). This is the same two-file lesson from Day 40's container task — the shape of the problem didn't change just because it's in a Dockerfile now.

**`DEBIAN_FRONTEND=noninteractive` isn't optional.** Without it, `apt-get install apache2` on `ubuntu:24.04` hangs on the `tzdata` prompt — waiting for input that never comes, in a non-interactive build. The build spins forever and looks like a network problem. One `ENV` line prevents it.

**`CMD ["apache2ctl", "-D", "FOREGROUND"]` — the "stay alive" line.** A container has no init system. If you run `apache2ctl start`, Apache daemonizes itself (forks to background, detaches from PID 1), and the container exits immediately because its foreground process is done. `-D FOREGROUND` tells Apache *not* to daemonize — it stays in the foreground as PID 1, which is what keeps the container running.

**`EXPOSE 5004` is metadata only.** It documents the port in `docker inspect`. It doesn't bind anything — that's what `sed` on `ports.conf` does. Both are needed for different reasons: the `sed` for runtime behavior, the `EXPOSE` for the image's declared shape. Some graders check both.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create KMS Key and Manage Encrypt/Decrypt of `SensitiveData.txt`

I was tasked with:

1. Create a symmetric KMS key named `datacenter-KMS-Key`
2. Encrypt `/root/SensitiveData.txt`, base64-decode the ciphertext, save as `/root/EncryptedData.bin`
3. Decrypt the same and verify the decrypted data matches the original
4. Ensure the KMS key is correctly configured so the validator can decrypt `EncryptedData.bin`

### What I Did — and the Error Chain

**Attempt 1 — Invented the tag flag:**

```bash
aws kms create-key --tags-specifications 'ResourceType=kms,Tags=[{Key=Name,Values=datacenter-KMS-Key}]'
```

```
Unknown options: --tags-specifications, ...
```

`--tags-specifications` doesn't exist. This is EC2/ELB syntax. KMS is a different API family.

**Attempt 2 — Fixed `Values=` → `Value=`, kept the wrong flag:** Same error.

**Attempt 3 — Dropped the `s` in `tags-specifications`:** Still wrong — the flag doesn't exist for `kms create-key` at all.

**Attempt 4 — The correct KMS-specific shape:**

```bash
aws kms create-key --tags TagKey=Name,TagValue=datacenter-KMS-Key
```

Success. Returned `KeyId: c9066077-fac3-4286-88f3-ba21ad3cd2f9`, `KeyManager: CUSTOMER`, `KeySpec: SYMMETRIC_DEFAULT`, `KeyState: Enabled`.

**Attempt 5 — Alias without the required prefix:** `ValidationException: Alias must start with the prefix "alias/"`

**Attempt 6 — Prefixed with `alias/`:** Success.

**Attempt 7 — Wrong path form for the plaintext file:**

```bash
aws kms encrypt --key-id c9066077-... --plaintext file://root/SensitiveData.txt
```

```
Unable to load paramfile file://root/SensitiveData.txt: [Errno 2] No such file or directory
```

Two mistakes: `file://` (single slash after scheme) is *not* the binary flag, and `root/SensitiveData.txt` is a relative path.

**Attempt 8 — Changed to `fileb://`, kept the relative path:** Same error. `fileb://` is correct for binary input, but the path is still relative.

**Attempt 9 — Absolute path with triple slash:**

```bash
aws kms encrypt --key-id c9066077-... --plaintext fileb:///root/SensitiveData.txt
```

Success. Returned `CiphertextBlob` (base64 text).

**Attempt 10 — The final command wrote to the wrong place with a made-up field:**

```bash
aws kms encrypt --key-id c9066077-... --plaintext fileb:///root/SensitiveData.txt \
  --output text --query Encrypted.bin > dec.b64
```

Ran without error — but `Encrypted.bin` is not a valid query field. The real field is `CiphertextBlob`. The pipeline wrote to `dec.b64` instead of `/root/EncryptedData.bin`, and never ran the required `base64 --decode` step.

**End-of-day state:** key exists ✅, alias exists ✅, encryption works ✅, **but `/root/EncryptedData.bin` was never correctly produced.** Task was in progress at day end.

### The Correct Pipeline

```bash
aws kms encrypt \
  --key-id alias/datacenter-KMS-Key \
  --plaintext fileb:///root/SensitiveData.txt \
  --output text \
  --query CiphertextBlob \
| base64 --decode > /root/EncryptedData.bin

aws kms decrypt \
  --ciphertext-blob fileb:///root/EncryptedData.bin \
  --output text \
  --query Plaintext \
| base64 --decode > /root/DecryptedData.txt

diff /root/SensitiveData.txt /root/DecryptedData.txt && echo MATCH
```

### Key Learning

**The base64 trap is the actual content of this task.** `aws kms encrypt` returns `CiphertextBlob` as **base64-encoded text** — JSON can't carry raw binary. If you save it directly to a file and then try to decrypt with `fileb://`, you get `InvalidCiphertextException` because the file is base64 text, not the original ciphertext. The `base64 --decode` step converts the text back to binary. **Same on decrypt** — `Plaintext` also comes back base64-encoded, so it needs a decode before comparing to the original.

The shape:

```
Encrypt:  bytes → KMS → base64 text → decode → binary ciphertext file
Decrypt:  binary ciphertext → KMS → base64 text → decode → plaintext bytes
```

**Four different services, four different tag shapes:**

| Service | Tag flag |
|---|---|
| **KMS** | `--tags TagKey=Name,TagValue=foo` |
| **EC2 / ELB / RDS** | `--tag-specifications 'ResourceType=...,Tags=[{Key=Name,Value=foo}]'` |
| **S3** | `--tagging 'TagSet=[{Key=Name,Value=foo}]'` |
| **Lambda** | `--tags 'Key=Name,Value=foo'` |

Same concept, four shapes. **The tag flag is per-service, not per-concept.** This is the same class of lesson as Day 38 (`executionRoleArn` vs `RoleArn`), Day 39 (`--acl public-read` vs bucket policy), Day 40 (`--vpc-id Values=...` vs `--vpc-id vpc-...`), and today's `--tags-specifications` vs `--tags`.

**`file://` vs `fileb://` — and the slash count.**

| Form | What it means |
|---|---|
| `file://path` | Load a text file |
| `fileb://path` | Load a binary file |
| `file:///root/x` | Absolute path, text mode |
| `fileb:///root/x` | Absolute path, binary mode |
| `fileb://root/x` | **Relative** path `./root/x` — usually wrong |

Triple-slash = `fileb:` + `//` + `/root/x`. Two-slashes-with-relative-path is valid syntax but wrong semantics.

**Alias must start with `alias/`.** Namespace separator in the API, not a display convention.

---

## 3. Personal Task — Terraform

### Task A: Delete IAM Role Using Terraform

I was tasked with deleting an existing IAM role via Terraform while keeping the provisioning code intact for future use.

### What I Did

**Step 1 — Inspected the working directory to see what was already in state:**

```bash
cd /home/bob/terraform
terraform state list
```

Output showed the role and, crucially, its **attached policies**:

```
aws_iam_role.this
aws_iam_role_policy_attachment.this
```

**Step 2 — Targeted both resources together:**

```bash
terraform destroy \
  -target=aws_iam_role_policy_attachment.this \
  -target=aws_iam_role.this
```

The plan showed the attachment destroy first (dependency order), then the role. Applied with `yes`.

**Step 3 — Verified:**

```bash
terraform state list
```

Empty — both resources gone from state. The `main.tf` still contained both resource blocks, ready for re-provisioning.

**Step 4 — Confirmed in AWS:**

```bash
aws iam get-role --role-name <role-name>
```

```
An error occurred (NoSuchEntity) when calling the GetRole operation: The role with name <role-name> cannot be found.
```

Role gone. ✅

### Task B: Delete VPC Using Terraform

I was tasked with deleting an existing VPC via Terraform, again keeping the provisioning code intact.

### What I Did

**Step 1 — Inspected what the VPC config contained:**

```bash
terraform state list
```

Output:

```
aws_vpc.this
aws_subnet.public
aws_internet_gateway.this
aws_route_table.public
aws_route_table_association.public
```

Five resources, all children of the VPC.

**Step 2 — Targeted the whole chain:**

```bash
terraform destroy \
  -target=aws_vpc.this \
  -target=aws_subnet.public \
  -target=aws_internet_gateway.this \
  -target=aws_route_table.public \
  -target=aws_route_table_association.public
```

Terraform's plan ordered the destruction correctly:
1. Route table association first
2. Route table
3. IGW detach + delete
4. Subnet
5. VPC last

Applied with `yes`.

**Step 3 — Verified state:**

```bash
terraform state list
```

Empty. ✅

**Step 4 — Verified in AWS:**

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=<vpc-name>"
```

```json
{ "Vpcs": [] }
```

VPC gone. ✅

### Issues I Faced and How I Fixed Them

**Issue 1 — First attempt on IAM role failed with `DeleteConflict`**

Tried `terraform destroy -target=aws_iam_role.this` first — the role still had a managed policy attached, so AWS refused:

```
DeleteConflict: Cannot delete entity, must detach all policies first.
```

**Fix:** Included the `aws_iam_role_policy_attachment.this` in the same destroy command, plus ordering. Targeting both together lets Terraform destroy the attachment first, then the role. A single `-target` was insufficient.

**Issue 2 — First attempt on VPC failed with `DependencyViolation`**

Tried `terraform destroy -target=aws_vpc.this` alone:

```
DependencyViolation: The vpc 'vpc-xxx' has dependencies and cannot be deleted.
```

**Fix:** Targeted all five child resources together. Terraform's dependency graph computed the correct teardown order.

**Issue 3 — Considered plain `terraform destroy` but backed out**

Plain `destroy` would have destroyed *everything* in the state — which in this lab was exactly the VPC chain, but the safe discipline is: **`-target` unless you're certain the state contains only this task's resources.** In a real environment, there would be other resources in state (ALBs, RDS, etc.) that a plain destroy would remove. `-target` is surgical.

### Key Learning

**Two deletion patterns, one dependency graph principle.**

The `-target` flag on `terraform destroy` **does not skip the dependency graph**. Terraform still computes ordering among the targeted resources — the attachment before the role, the route table association before the route table, the subnet before the VPC. What `-target` does is **limit the set of resources under consideration**, not **skip ordering**.

This is subtle and important:

| Pattern | What it does |
|---|---|
| `terraform destroy` | Destroys everything in state; dependency order respected |
| `terraform destroy -target=A` | Destroys only A; **fails** if A depends on B still present |
| `terraform destroy -target=A -target=B` | Destroys A and B; **dependency order respected between them** |

**The failure modes are the same lesson in two services:**

- **IAM `DeleteConflict`** — cannot delete a role with attached policies or users
- **VPC `DependencyViolation`** — cannot delete a VPC with subnets, route tables, IGWs, SGs

Both are the same statement at the API layer: **"this resource has children, remove them first."** Terraform can handle it automatically when the whole graph is in scope. On `-target`, you must name the whole chain.

**The dependency chains differ per service — and this is worth memorizing for both:**

| Service | Delete order |
|---|---|
| **IAM role** | `aws_iam_role_policy_attachment` → `aws_iam_role_policy` (inline) → remove from `aws_iam_instance_profile` → `aws_iam_role` |
| **VPC** | `aws_route_table_association` → `aws_route_table` → `aws_internet_gateway` (detach then delete) → `aws_subnet` → `aws_security_group` → `aws_vpc` |

**Verification, in both cases, is the `describe` the grader will use.** `terraform state list` is *Terraform's* view. `aws iam get-role` and `aws ec2 describe-vpcs` are *AWS's* view. If state is empty but AWS still shows the resource → the destroy didn't actually happen (a race, a failed API call, a `--force` behavior not honored). If state has the resource but AWS shows it gone → someone deleted out-of-band and Terraform's state is stale. **Both have to be empty; that's the actual definition of "deleted."**

**Same discipline as Day 40's `aws_instance_delete` — the resource doesn't need a "delete" block.** The provisioning code stays intact; the destroy is a CLI operation, not an HCL construct. There is no `aws_iam_role_delete` or `aws_vpc_delete`. **`-target` on `terraform destroy` is the only correct tool.**

---

## Key Takeaways

- 🐳 **Changing the Apache port requires two files** — `ports.conf` (binding) and `000-default.conf` (vhost). Same lesson as Day 40's container task.
- 🐳 **`DEBIAN_FRONTEND=noninteractive` is mandatory for `apt` in Docker builds** — `tzdata` prompts hang the build forever.
- 🐳 **`CMD ["apache2ctl", "-D", "FOREGROUND"]`** — containers have no init system; foreground is what keeps them alive.
- 🔑 **KMS tags use `--tags TagKey=Name,TagValue=foo`, not `--tag-specifications`.** Four AWS services, four tag shapes.
- 🔑 **Aliases must start with `alias/`** — namespace separator, not display convention.
- 🔑 **`fileb:///root/x` is absolute, `fileb://root/x` is relative.** Triple slash = scheme + `//` + absolute path.
- 🔑 **KMS returns base64-encoded ciphertext and plaintext.** If you need a binary file, pipe through `base64 --decode`. Skipping it fails `InvalidCiphertextException` on reload.
- 🔑 **`--query Encrypted.bin` was invented.** Real field: `CiphertextBlob`.
- 🔧 **`-target` on `terraform destroy` does NOT skip the dependency graph.** It limits the scope; ordering still computed among targeted resources.
- 🔧 **A single `-target` for a resource with children will fail.** IAM role → needs attachments too. VPC → needs subnets, RTBs, IGW, SG too.
- 🔧 **Both `terraform state list` and `aws describe-*` must be empty.** Terraform's view alone isn't proof of deletion.
- 🔧 **There is no `aws_iam_role_delete` or `aws_vpc_delete` resource.** Provisioning code stays; destroy is a CLI verb. Same as Day 40's `aws_instance_delete` lesson.

---

## Day Status

| Area                                              | Status       |
| ------------------------------------------------- | ------------ |
| 100 Days DevOps — Dockerfile for Apache 5004      | 🟢 Completed |
| 100 Days Cloud — KMS key + encrypt/decrypt         | 🟡 In progress (encrypt works, final file needs fix) |
| Personal — Terraform delete IAM role              | 🟢 Completed |
| Personal — Terraform delete VPC                   | 🟢 Completed |
| Docker (Dockerfile authoring, CMD foreground)     | 🟢 Learned   |
| AWS (KMS key lifecycle, alias, tag shape)          | 🟢 Learned   |
| Terraform (targeted destroy, dependency chains)   | 🟢 Reinforced |

**Overall: 🟡 Day 41/100 — Partially completed (KMS final file still to fix)**

> **Major realization:** Today produced **five error messages in a row on KMS** — every one a shape assumption from another service — and then **two `-target` failures on Terraform** — both a dependency assumption. The pattern is identical across both stacks: **the tool's model is narrower than my expectation of it, and the error names the gap.**
>
> The Terraform failures are the most useful because the fix taught the mechanism, not just the command. `-target` on a resource with children doesn't shortcut; it *fails*, because Terraform still respects the graph and refuses to violate it. That's not a bug — it's Terraform enforcing what AWS would refuse anyway (`DeleteConflict`, `DependencyViolation`). **Terraform surfaces the dependency instead of hiding it.** The fix — listing the whole chain in `-target` — teaches the chain. That's a map I now have for two of the most common AWS deletions.
>
> And then the KMS close: after all five failures, the "success" command that ran silently was the worst one — `--query Encrypted.bin` returned no error, wrote a wrong file, and looked like progress. **Same lesson as yesterday in a harder form: the command that fails loudly is a gift; the command that fails silently is the trap.** The verification isn't "did the command return" — it's "does the output load the way the consumer will load it." The grader uses `fileb://`. The only way to know the file is binary is to load it the same way. **Anything short of that is assumption dressed as success.**
