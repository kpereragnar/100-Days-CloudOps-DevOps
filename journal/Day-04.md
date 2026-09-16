# CloudOps / DevOps Journal

## Day 4 — 16 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud (AWS)

---

## 1. 100 Days of DevOps Challenge

### Task

Add execution permissions for everyone on **App Server 1** to a newly created file with no permissions.

### First Attempt

I was very confident with this task because I was already familiar with Linux file permissions.

After SSHing into App Server 1, I ran:

```bash
sudo chmod ugo+x /tmp/xfusioncorp.sh
```

I was confident that this was the correct command because `ugo+x` adds execute permission for the **user, group, and others**.

Because I was so confident, I did not verify the permissions or execute the file before submitting the task.

I submitted the task.

### Result

❌ **Task Failed**

At this point, I realized that I had made an important mistake: I had assumed that my command was sufficient without actually verifying the result.

---

### Second Attempt — Investigation

I redid the task and again applied:

```bash
sudo chmod ugo+x /tmp/xfusioncorp.sh
```

This time, instead of immediately submitting the task, I decided to actually verify that the file could be executed.

I attempted to execute the file.

The result was:

```text
Permission denied
```

This was when I discovered the actual problem.

### Investigating the Permissions

The `ugo+x` command had added execute permission, but the file still did not have read permission.

The permission state was effectively:

```text
---x--x--x
```

The file could be marked as executable, but because it was a shell script, the shell/interpreter needed to be able to read the script's contents.

### Root Cause

My initial assumption was:

```bash
chmod ugo+x /tmp/xfusioncorp.sh
```

was enough because the task specifically asked for execution permission.

However, after actually executing the script, I received:

```text
Permission denied
```

The problem was that the shell script also needed read permission.

Therefore, I needed:

```text
r-x r-x r-x
```

rather than:

```text
--x --x --x
```

### Solution

I changed the permissions to give everyone both read and execute permissions:

```bash
sudo chmod ugo+rx /tmp/xfusioncorp.sh
```

I then executed the file again and it worked.

### What I Learned

The biggest lesson from this task was not simply learning another `chmod` command.

It was learning the importance of **verification**.

On my first attempt, I was so confident that I did not check my work. I assumed that because the command was correct and executed without an error, the task was complete.

That assumption caused me to fail the task.

On my second attempt, I took a different approach. I actually tested the file instead of assuming it worked. The `Permission denied` error exposed the problem and allowed me to investigate the permissions properly.

This reinforced several important habits:

- Never rely solely on confidence.
- Always verify the result of a command.
- Test the actual operation where possible.
- Understand what each permission actually does.
- When something fails, investigate the underlying cause instead of simply repeating the same command.

Useful verification commands include:

```bash
ls -l /tmp/xfusioncorp.sh
```

and:

```bash
/tmp/xfusioncorp.sh
```

### Technical Note

`chmod ugo+x` does correctly add execute permission to the file. However, this particular file was a **shell script**, so the interpreter needed to read its contents.

Therefore:

```bash
chmod ugo+x /tmp/xfusioncorp.sh
```

resulted in execute-only permissions, while:

```bash
chmod ugo+rx /tmp/xfusioncorp.sh
```

provided both read and execute permissions.

This explains why the second attempt produced `Permission denied` when I actually tried to execute the script.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

Enable versioning for an S3 bucket.

### Method

I completed the task using the AWS CLI.

### Status

✅ Completed

### Issues Encountered

None.

### Lesson Learned

I gained more practical experience managing S3 bucket configuration through the AWS CLI, specifically enabling versioning.

---

## 3. Personal Cloud Practice — AWS

### Tasks

I practiced the lifecycle management of an EC2 instance:

- Creating an instance.
- Modifying an instance.
- Deleting an instance.

### Creation

I successfully created the EC2 instance without encountering any issues.

### Modification

When I attempted to modify the instance, I discovered that some EC2 configuration changes require the instance to be stopped first.

I initially did not know that the instance needed to be stopped before making the modification.

### Solution

I stopped the instance, made the required modification, and continued with the exercise.

### Deletion

I did not encounter any issues while deleting the instance.

However, I initially attempted to use:

```bash
delete-instance
```

before realizing that the correct AWS EC2 CLI operation for permanently removing an instance is:

```bash
terminate-instances
```

### Lesson Learned

This exercise reinforced the importance of understanding the EC2 instance lifecycle:

```text
Launch → Run → Stop → Modify (where required) → Start → Terminate
```

I also learned that AWS CLI command names must be precise. The correct EC2 operation is:

```bash
aws ec2 terminate-instances
```

not:

```bash
delete-instance
```

---

# Day 4 — Key Takeaways

Today's biggest lesson came from the DevOps task.

> **Never be so confident in your answer that you skip verification.**

### Technical Lessons

- `chmod ugo+x` adds execute permission for the user, group, and others.
- Shell scripts need to be readable by the interpreter in order to execute normally.
- `chmod ugo+rx` adds both read and execute permissions for everyone.
- `ls -l` can be used to inspect file permissions.
- Executing the file is another way to verify that the permission configuration actually works.
- S3 bucket versioning can be enabled through the AWS CLI.
- Some EC2 modifications require the instance to be stopped first.
- EC2 instances are terminated using `terminate-instances`.

### Personal Learning Lesson

The most important lesson from Day 4 was the difference between **thinking something is correct and proving that it works**.

On my first attempt, I was very confident that:

```bash
sudo chmod ugo+x /tmp/xfusioncorp.sh
```

was enough, so I didn't verify the result before submitting the task.

The task failed.

On my second attempt, I redid the command but this time actually executed the file to verify it. That's when I encountered:

```text
Permission denied
```

That error led me to investigate the file permissions and discover that the shell script also needed read permission.

**Confidence without verification caused the first failure. Verification led to the solution.**

---

## Day 4 Status

| Area                       | Status       |
| -------------------------- | ------------ |
| 100 Days DevOps Challenge  | ✅ Completed  |
| AWS Cloud Challenge        | ✅ Completed  |
| EC2 Creation Practice      | ✅ Completed  |
| EC2 Modification Practice  | ✅ Completed  |
| EC2 Termination Practice   | ✅ Completed  |
| Linux Permissions          | 🟢 Practiced |
| Shell Script Execution     | 🟢 Practiced |
| S3 Versioning              | 🟢 Practiced |
| EC2 Lifecycle              | 🟢 Practiced |

**Overall: 🟢 Day 4/100 — Completed**

**Major realization:** *Never be too confident to verify your work.*
