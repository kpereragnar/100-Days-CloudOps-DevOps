# Day 2 — 14 September 2026

## Challenges

- 100 Days of DevOps Challenge — KodeKloud
- 100 Days of Cloud Challenge — KodeKloud

## Challenge Tasks Completed

- Completed Day 2 of the DevOps Challenge
- Completed Day 2 of the Cloud Challenge
- Completed AWS tasks
- Completed Azure tasks

## Personal Learning

Today I went beyond the assigned challenge tasks and practiced AWS IAM.

### AWS IAM

Practiced:

- Creating IAM users
- Creating IAM groups
- Creating access keys
- Creating IAM policies
- Attaching policies
- Granting permissions to users
- Using IAM users with the AWS CLI

---

# Issues Encountered

## 1. Azure VM SSH Key Pair

### Problem

While completing the Azure Cloud Challenge, I was required to create an Azure VM.
However, Azure refused to create the SSH key pair during the VM creation process.

### Solution

I created the SSH key pair separately first.

After creating the key pair:

1. Returned to the VM creation process.
2. Selected the previously created key pair.
3. Continued with the VM deployment.

### Lesson Learned

Cloud platforms sometimes combine multiple resource-creation operations into a
single workflow. When one component fails, creating the dependency separately
can sometimes resolve the issue.

---

## 2. AWS IAM User Permissions

### Problem

After creating a new IAM user, I attempted to create an EC2 instance using the
AWS CLI.

The operation failed because the IAM user did not have sufficient permissions
to access the required EC2 resources.

### Root Cause

Creating an IAM user does not automatically give that user permission to perform
AWS operations.

The user could authenticate, but did not have authorization to create the EC2
resource.

### Solution

I returned to IAM and configured the required permissions for the user.

After granting the appropriate permissions, I was able to access the required
AWS resources.

### Lesson Learned

AWS IAM separates authentication from authorization.

**Authentication:** Who are you?

**Authorization:** What are you allowed to do?

An IAM identity can successfully authenticate while still being denied access
to AWS resources.

---

# Key Takeaways

Today's major focus was AWS IAM and access control.

I learned that creating an IAM user is only the beginning. The identity must
also have appropriate permissions through policies, groups, roles, or other
authorization mechanisms.

I also gained practical troubleshooting experience with both AWS and Azure.

## Status

🟢 **Day 2/100 — Completed**

