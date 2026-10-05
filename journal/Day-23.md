```markdown
# CloudOps / DevOps Journal

## Day 23 — 5 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Fork a Git Repository (GUI)

I was tasked with forking a Git repository through the GUI.

### What I Did

Since I had already worked through **Git L1 and L2** tasks in previous days, the concept of forking was already familiar. I navigated to the repository on the Git hosting platform, clicked the **Fork** button, and selected the destination account.

The fork was created instantly, giving me my own copy of the repository under my account.

### Key Learning

> **The Git skills I've built are starting to compound.**

Tasks that would have required research a few weeks ago are now routine. Forking — which involves creating a personal copy of someone else's repository — is a fundamental Git collaboration workflow, and having done it multiple times before meant this task took under a minute.

The reinforcement: **understanding Git concepts makes platform-specific UIs trivial to navigate.** Whether it's GitHub, GitLab, or Bitbucket, the "Fork" button does the same thing.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Migrate Data Between Two S3 Buckets

I was tasked with:

1. Creating a new private S3 bucket named `datacenter-sync-955998916`
2. Migrating all data from `datacenter-s3-955998916` to the new bucket
3. Ensuring both buckets contain the same data
4. Using the AWS CLI for both tasks

### What I Did

**Step 1 — Confirmed credentials:**

```bash
aws sts get-caller-identity
```

**Step 2 — Inspected the source bucket:**

```bash
aws s3 ls s3://datacenter-s3-955998916/ --recursive --human-readable --summarize
```

**Step 3 — Created the new bucket:**

```bash
aws s3 mb s3://datacenter-sync-955998916 --region us-east-1
```

**Step 4 — Blocked all public access (explicit privacy):**

```bash
aws s3api put-public-access-block \
  --bucket datacenter-sync-955998916 \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**Step 5 — Migrated the data:**

```bash
aws s3 sync s3://datacenter-s3-955998916/ s3://datacenter-sync-955998916/
```

**Step 6 — Verified data consistency:**

```bash
# Compare object counts
aws s3 ls s3://datacenter-s3-955998916/ --recursive | wc -l
aws s3 ls s3://datacenter-sync-955998916/ --recursive | wc -l

# Compare total sizes
aws s3 ls s3://datacenter-s3-955998916/ --recursive --summarize | tail -2
aws s3 ls s3://datacenter-sync-955998916/ --recursive --summarize | tail -2
```

Both matched.

### Key Learning

**S3 buckets are private by default.** No ACL or policy is required to make a new bucket private — the modern AWS default is that nothing is public unless you explicitly make it so. Adding `put-public-access-block` is a **defense-in-depth** step that ensures the bucket rejects any future attempt to become public, even by accident.

**`aws s3 sync` is the correct tool for migrations — not `s3 cp` or `copy-object`:**

| Command | Behavior |
|---|---|
| `s3 sync` | Copies only files that don't exist or have changed. Idempotent. Resumable. |
| `s3 cp --recursive` | Re-copies every file every run. Wastes bandwidth on retries. |
| `s3api copy-object` | One object per API call. You'd have to write a loop yourself. |

`sync` uses `copy-object` under the hood — but adds decision logic (skip unchanged files), parallelization (multiple transfers at once), and resumption (picks up after failures). That's why it's the right tool for a bucket migration.

**Also reinforced the trailing slash rule:**

```bash
aws s3 sync s3://source/ s3://dest/    # ✅ copies CONTENTS
aws s3 sync s3://source s3://dest/     # ❌ copies the BUCKET as a subfolder
```

Without the trailing slash on the source, files end up nested under `s3://dest/source/` instead of directly under `s3://dest/`.

**Two CLI layers exist for S3:**

- `aws s3 mb` — high-level, automatically handles `LocationConstraint` for non-`us-east-1` regions
- `aws s3api create-bucket` — low-level, requires you to pass `--create-bucket-configuration LocationConstraint=<region>` explicitly

Both work. High-level is simpler; low-level gives you the raw JSON response when you need it.

---

## 3. Personal Task — Ansible L1

### Completed Ansible L1

I completed the final tasks in **Ansible L1**, marking the completion of the entire level.

**Ansible L1 covered:**

- ✅ Installation and configuration of Ansible
- ✅ Building inventory files (INI format)
- ✅ Ad-hoc commands across multiple hosts
- ✅ Writing playbooks to copy files and configure services
- ✅ Setting default SSH users via `ansible.cfg`
- ✅ Working with host variables (`ansible_host`, `ansible_user`, `ansible_ssh_pass`)
- ✅ Running playbooks with `ansible-playbook -i inventory playbook.yml`

### Key Learning

The moment it clicked for me this week: **Ansible is "describe the desired state across N servers, once."**

Instead of SSHing into 7 servers and typing the same commands over and over, I write one playbook and it runs across all of them — in parallel, idempotently, and safely.

Two concepts that made everything fall into place:

**1. Idempotency.** Running a playbook 100 times produces the same result as running it once. If a package is installed, `yum: state=present` does nothing. If a service is running, `service: state=started` does nothing. No "already exists" errors. No duplicate work.

**2. The playbook skeleton is short.** Every playbook follows the same 6-line structure:

```yaml
---
- name: <description>
  hosts: <target>
  become: yes
  tasks:
    - name: <task>
      <module>:
        <param>: <value>
```

Everything else is filling in the blanks. The module parameters are lookup-able with `ansible-doc -s <module>` — no engineer memorizes them all.

### Where I Got Stuck and How I Fixed It

The most common error I hit was the YAML indentation error:

```
did not find expected '-' indicator
```

**Root cause:** YAML uses indentation as syntax — sibling list items must be at the **same column**. When the two tasks in my playbook weren't aligned, the parser couldn't tell if the second task was a sibling or nested content, so it failed.

**Fix:** Use **2-space indentation consistently** throughout. Alignment matters more than the exact number of spaces.

I also learned to delete tasks that don't do anything. The "confirm file exists" task I initially added was useless — the `copy` module already creates the file. Every task in a playbook should have a clear reason to exist.

---

## Key Takeaways

- 🍴 **Forking is a standard Git workflow** — once you understand Git concepts, the platform UI becomes trivial.
- 🗄️ **`aws s3 sync` is the migration tool.** Idempotent, resumable, parallel. Not `cp` or `copy-object`.
- 🔒 **S3 buckets are private by default** — no policy needed. Block public access is defense-in-depth.
- 📏 **YAML indentation is syntax, not style.** Sibling list items must align exactly.
- 🧹 **Every playbook task should do something.** Delete "confirm" or "verify" tasks — the grader handles validation.
- ⚙️ **Ansible's power is idempotency + parallelism.** Describe the desired state; let Ansible figure out what to change.
- 🧠 **Reps beat memorization.** Nobody writes 50-line playbooks from scratch memory. The top 10 modules + docs is the real skill.
- 🎯 **Ansible L1 complete.** Moving to L2 (roles, handlers, vault) next.

---

## Day Status

| Area                     | Status       |
| ------------------------ | ------------ |
| 100 Days DevOps          | 🟢 Completed |
| 100 Days Cloud — AWS     | 🟢 Completed |
| Personal Ansible L1      | 🟢 Completed |
| Git (forking)            | 🟢 Reinforced |
| AWS S3 (migration)       | 🟢 Completed |
| Ansible (foundations)    | 🟢 L1 Complete |

**Overall: 🟢 Day 23/100 — Completed**

> **Major realization:** Both the Git and AWS tasks today were "easy" — not because they were trivial, but because **the foundations I'd built in previous days made them easy**. Forking a repo took a minute because I'd already done it. Migrating S3 buckets took minutes because I understood `sync` vs `cp`. The compound effect of consistent daily practice is exactly this: tasks that would have taken hours a month ago now take minutes. The Ansible L1 completion this week marks another foundation laid — everything built on it from here gets easier.
```


