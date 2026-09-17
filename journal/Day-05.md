Markdown

````
# CloudOps / DevOps Journal

## Day 5 — 17 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud (AWS)

---

## 1. 100 Days of DevOps Challenge

### Task

Following a security audit, the **xFusionCorp Industries** security team decided to improve application and server security by introducing **SELinux**.

The requirements for **App Server 3** in the **Stratos Datacenter** were:

- Install the required SELinux packages.
- Permanently disable SELinux for the time being.
- SELinux will be re-enabled after the necessary configuration changes.
- No reboot was required because a scheduled maintenance reboot was already planned for the night.
- The current SELinux status shown through the command line could be disregarded because the expected final status after reboot was **disabled**.

### Approach

I connected to App Server 3 and began installing the required SELinux packages.

### Issue Encountered

My first attempt was to use `apt`, but the command did not work as expected.

I then recognized that the server environment required `yum` instead, so I used `yum` to install the necessary packages and continued with the task.

### Solution

I used the appropriate package manager for the server and permanently disabled SELinux according to the task requirements.

The task was completed successfully without needing to reboot the server immediately.

### New Concept Learned: SELinux

This was my first practical exposure to **SELinux**.

I learned that SELinux is a security system based on **Mandatory Access Control (MAC)**.

#### Traditional Linux Permissions — DAC

Traditional Linux file permissions are based on **Discretionary Access Control (DAC)**.

With DAC:

- File owners can control permissions.
- Users and groups determine access.
- Permissions are commonly managed with commands such as:
  - `chmod`
  - `chown`
  - `chgrp`

#### SELinux — MAC

SELinux uses **Mandatory Access Control (MAC)**.

With MAC:

- Access decisions are enforced by security policies.
- Even if traditional Linux permissions allow an action, SELinux policies can still restrict it.
- Access is controlled based on security contexts, policies, and defined rules.

### Lesson Learned

This task introduced me to an important Linux security concept that I had not previously worked with.

I learned the difference between:

- **DAC:** Access controlled primarily by file ownership and permissions.
- **MAC:** Access controlled by centrally enforced security policies.

I also learned that package-management commands can differ depending on the Linux distribution. When `apt` did not work, I had to identify and use the appropriate package manager, `yum`.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

Create an AWS **gp3 EBS volume** with the name:

```text
nautilus-volume
````

### Initial Investigation

Before completing the task, I had to clarify the difference between Amazon S3 and EBS gp3 because I was initially unsure how they differed.

### What I Learned: EBS gp3 vs S3

#### Amazon EBS gp3

An EBS gp3 volume is a type of block storage.

It is designed to be attached to an EC2 instance and functions similarly to a physical HDD or SSD attached to a computer.

Common characteristics include:

* Block-level storage.

* Usually attached to an EC2 instance.

* Used for operating systems, applications, databases, and persistent files.

* Supports configurable storage performance characteristics.

#### Amazon S3

Amazon S3 is an object storage service.

It stores data as objects inside buckets and can be accessed through:

* AWS APIs.

* The AWS CLI.

* SDKs.

* Applications.

Common object operations include:

* `GET`

* `PUT`

* `DELETE`

A simple analogy is that S3 is more like a cloud-based object storage system where files are stored as objects and accessed through applications or APIs. However, unlike Google Drive, S3 is primarily designed for application workloads, backups, datasets, static assets, and large-scale cloud storage.

### Initial Attempt

I attempted to create the gp3 volume but forgot to assign the required name:

```
nautilus-volume
```

The task specifically required the name to be supplied using `--tag-specifications`.

I skipped that part during the creation command.

### Result

❌ Initial Attempt Failed

The volume was created, but it did not fully satisfy the task because the required name tag was missing.

### Correction

I redid the task and included the required tag specification during volume creation.

For example:

Bash

```
aws ec2 create-volume \
  --availability-zone <availability-zone> \
  --size <size-in-gib> \
  --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=nautilus-volume}]'
```

The exact availability zone and size should be replaced with the values specified by the task.

### Lesson Learned

The main lesson from this task was the importance of verifying cloud resources after creation.

Creating a resource successfully does not automatically mean that every required configuration has been applied.

After creating resources, I should use commands such as:

Bash

```
aws ec2 describe-volumes
```

or, when necessary:

Bash

```
aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=nautilus-volume"
```

These commands help confirm that:

* The resource exists.

* The volume type is correct.

* The size is correct.

* The availability zone is correct.

* The required tags are present.

* The resource aligns with the task requirements.

### Cloud Storage Comparison

|
Feature

|

EBS gp3

|

Amazon S3

|
| --- | --- | --- |
|

Storage type

|

Block storage

|

Object storage

|
|

Common use

|

EC2 disks, operating systems, databases

|

Files, backups, datasets, and application objects

|
|

Access model

|

Attached to EC2 through EBS

|

API, CLI, SDK, and applications

|
|

Similar concept

|

HDD or SSD attached to a computer

|

Cloud-based object storage

|
|

Main resource

|

Volume

|

Bucket and objects

|

## 3. Personal Cloud Practice — AWS

### Topic Learned

Today, I learned about Amazon Machine Images (AMIs).

### What Is an AMI?

An Amazon Machine Image (AMI) is a template used to launch EC2 instances.

An AMI can contain:

* An operating system.

* Preinstalled software.

* Application configurations.

* System settings.

* Required packages and dependencies.

When launching an EC2 instance, the AMI provides the initial configuration from which the instance is created.

### Why Engineers Create Custom AMIs

Engineers may create custom AMIs to:

* Standardize server configurations.

* Preinstall required applications and dependencies.

* Reduce deployment time.

* Create repeatable infrastructure.

* Preserve a known working server configuration.

* Support scaling by launching multiple instances with the same setup.

* Improve consistency across development, testing, and production environments.

* Create recovery or backup points for workloads.

For example, instead of manually installing and configuring Nginx, application dependencies, security tools, and monitoring agents on every new EC2 instance, an engineer can create a custom AMI containing those configurations and use it to launch consistently configured instances.

### Lesson Learned

I learned that AMIs are important for creating repeatable and standardized EC2 deployments.

They help engineers avoid configuring every server manually and make it easier to launch multiple instances with a consistent baseline.

# Day 5 — Key Takeaways

### Technical Lessons

* Linux distributions may use different package managers.

* `apt` and `yum` are package-management tools used in different Linux environments.

* SELinux provides Mandatory Access Control (MAC).

* Traditional Linux permissions are based on Discretionary Access Control (DAC).

* SELinux can restrict access even when traditional Linux permissions allow it.

* EBS gp3 is block storage designed to be attached to EC2 instances.

* Amazon S3 is an object storage service.

* AWS resource tags should be included when required by a task.

* `--tag-specifications` can be used to assign tags during AWS resource creation.

* `describe-volumes` can be used to verify EBS volume configuration.

* AMIs provide reusable templates for launching EC2 instances.

* Custom AMIs help standardize and speed up deployments.

### Personal Learning Lesson

Today's DevOps task introduced me to SELinux and the difference between DAC and MAC, while the AWS task reinforced the importance of understanding cloud storage types and verifying resource configurations after creation.

The biggest practical lesson was:

> Always confirm that a resource or configuration matches every requirement of the task—not just that the creation command completed successfully.

## Day 5 Status

|
Area

|

Status

|
| --- | --- |
|

100 Days DevOps Challenge

|

✅ Completed

|
|

AWS Cloud Challenge

|

✅ Completed

|
|

SELinux Fundamentals

|

🟢 Practiced

|
|

Linux Package Management

|

🟢 Practiced

|
|

AWS EBS gp3

|

🟢 Practiced

|
|

AWS Resource Tagging

|

🟢 Practiced

|
|

AWS Resource Verification

|

🟢 Practiced

|
|

Amazon Machine Images

|

🟢 Studied

|

Overall: 🟢 Day 5/100 — Completed

Major realization: Always verify that the final resource configuration matches the complete task requirements.

````
