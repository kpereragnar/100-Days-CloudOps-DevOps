````markdown
# CloudOps / DevOps Journal

## Day 7 — 19 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task

The system administrators team of **xFusionCorp Industries** had configured scripts on the jump host that run at regular intervals and perform operations across all application servers in the Stratos Datacenter.

For these scripts to work correctly, the `thor` user on the jump host needed **password-less SSH access** to all application servers through their respective sudo users.

The requirement was to configure password-less authentication from:

```text
thor@jump_host
        │
        ├──> tony@app_server_1
        ├──> <sudo_user>@app_server_2
        └──> <sudo_user>@app_server_3
```

### Approach

To complete the task, I configured SSH key-based authentication between the `thor` user on the jump host and the required sudo users on the application servers.

This was my first practical implementation of password-less SSH authentication, so I did some additional research before completing the task.

### New Concepts Learned

#### SSH Key-Based Authentication

Instead of authenticating with a password each time, SSH can use a pair of cryptographic keys:

- **Private key** — kept securely on the client machine.
- **Public key** — placed on the destination server.

The server uses the public key to verify that the connecting client possesses the corresponding private key.

A common command for installing a public key on a remote server is:

```bash
ssh-copy-id <user>@<server>
```

For example:

```bash
ssh-copy-id tony@app-server-1
```

After the public key has been installed, SSH authentication can be performed without manually entering the user's password.

### Security Considerations

While learning about password-less SSH, I also learned that **password-less authentication does not mean authentication without security**.

SSH keys must be protected because anyone who obtains an unprotected private key may potentially use it to authenticate as the associated user.

Some security best practices include:

- Protecting private keys with strong passphrases.
- Using `ssh-agent` to securely manage keys during a session.
- Restricting permissions on private key files.
- Avoiding unnecessary sharing of private keys.
- Using dedicated keys where appropriate.
- Removing or rotating keys that are no longer required.

For example:

```bash
chmod 600 ~/.ssh/id_rsa
```

An SSH agent can also be used to load a private key into memory:

```bash
ssh-add ~/.ssh/id_rsa
```

### Lesson Learned

This task helped me understand how automated infrastructure operations can use SSH key-based authentication instead of interactive password authentication.

I also learned that automation introduces additional security considerations because credentials and private keys must be properly protected.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task

Modify an existing EC2 instance from:

```text
t2.micro
```

to:

```text
t2.nano
```

### Approach

This task was straightforward because I had already practiced modifying an EC2 instance as part of my personal AWS practice earlier in the week.

I followed the required sequence:

### Step 1 — Find the Instance ID

I used:

```bash
aws ec2 describe-instances
```

to identify the required EC2 instance and obtain its **Instance ID**.

### Step 2 — Stop the Instance

Before modifying the instance type, I stopped the EC2 instance:

```bash
aws ec2 stop-instances \
  --instance-ids <instance-id>
```

### Step 3 — Modify the Instance Type

I changed the instance type using:

```bash
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --instance-type <value>
```

The required instance type was:

```text
t2.nano
```

### Step 4 — Start the Instance

After modifying the instance type, I started the instance again:

```bash
aws ec2 start-instances \
  --instance-ids <instance-id>
```

### Lesson Learned

This task reinforced the process for modifying EC2 instance attributes.

I also learned the importance of understanding which EC2 operations require an instance to be stopped before making changes.

The workflow was:

```text
Find Instance
     ↓
Stop Instance
     ↓
Modify Instance Type
     ↓
Start Instance
```

Because I had already practiced this process personally, I was able to complete the challenge without any major issues.

---

## 3. Personal AWS Cloud Practice

Today I continued my personal AWS CLI practice by working with **subnets**.

My goal was to become comfortable creating, modifying, and deleting subnets through the AWS CLI rather than relying on the AWS Management Console.

---

### 3.1 Create a Subnet Using the AWS CLI

I created a subnet using the AWS CLI.

The main issues I encountered were:

- Invalid subnet CIDR block.
- CIDR conflicts with existing subnets.

### CIDR Block Issue

One of the important things I learned was that a subnet's CIDR block must fit within the CIDR range of its VPC.

For example, if the VPC uses:

```text
172.31.0.0/16
```

the subnet must use an address range contained within that VPC.

A subnet cannot use:

```text
172.31.0.0/8
```

because `/8` represents a much larger network than `/16` and therefore extends outside the VPC's address space.

### Checking Existing Subnets

I also encountered conflicts caused by existing subnet CIDR ranges.

To investigate existing subnets, I used:

```bash
aws ec2 describe-subnets
```

This allowed me to inspect the existing subnet configurations and identify CIDR ranges that were already in use.

### Lesson Learned

Before creating a subnet, I should always check:

1. The VPC CIDR block.
2. Existing subnet CIDR blocks.
3. Whether the proposed subnet range is contained within the VPC.
4. Whether the proposed CIDR overlaps with an existing subnet.

This made me understand CIDR planning more practically rather than only theoretically.

---

## 3.2 Modify Subnet Attributes

I also practiced modifying subnet attributes using:

```bash
aws ec2 modify-subnet-attribute
```

One of the attributes I explored was **Map Public IP on Launch**.

### Map Public IP on Launch

When enabled, instances launched into the subnet can automatically receive a public IPv4 address, depending on the configuration and launch process.

This can simplify access to resources that need public connectivity, but it also has security implications.

Resources with public IP addresses may become directly reachable from the internet if their network and security-group configuration permits it.

This reinforced the importance of carefully considering whether a subnet should automatically assign public IP addresses.

### Security Consideration

Public accessibility should be intentional.

For workloads that do not need direct internet exposure, it is generally preferable to keep them in appropriately configured private subnets and control internet access through the required network architecture.

---

## 3.3 Delete a Subnet

Finally, I practiced deleting a subnet using the AWS CLI.

This gave me hands-on experience with the complete subnet lifecycle:

```text
Create
  ↓
Inspect
  ↓
Modify
  ↓
Delete
```

### Lesson Learned

Working through the complete lifecycle helped me understand that cloud infrastructure is not only about creating resources.

A CloudOps engineer also needs to understand how to:

- Inspect resources.
- Modify resources.
- Troubleshoot configuration issues.
- Understand dependencies.
- Safely remove resources when they are no longer required.

---

# Day 7 — Key Takeaways

## DevOps Lessons

- SSH supports key-based authentication for secure remote access.
- `ssh-copy-id` can be used to install a public SSH key on a remote server.
- Password-less SSH is useful for automation.
- Private SSH keys must be protected.
- `ssh-agent` can help manage private keys securely.
- Automated SSH access introduces additional credential-management considerations.

## AWS Lessons

- EC2 instance types can be modified using the AWS CLI.
- An EC2 instance generally needs to be stopped before changing its instance type.
- `describe-instances` can be used to retrieve instance information.
- `stop-instances` stops an EC2 instance.
- `modify-instance-attribute` can modify EC2 attributes.
- `start-instances` starts a stopped EC2 instance.
- Subnet CIDR blocks must fall within the VPC's CIDR range.
- Subnet CIDR ranges must not conflict with existing subnet ranges.
- `describe-subnets` can be used to inspect existing subnet configurations.
- `modify-subnet-attribute` can modify subnet settings.
- Automatically assigning public IP addresses has security implications.
- AWS CLI can be used to manage the complete subnet lifecycle.

---

# Day 7 Status

| Area | Status |
|---|---|
| 100 Days DevOps Challenge | ✅ Completed |
| SSH Key-Based Authentication | 🟢 Practiced |
| Password-less SSH | 🟢 Practiced |
| `ssh-copy-id` | 🟢 Learned |
| SSH Key Security | 🟢 Learned |
| `ssh-agent` | 🟢 Learned |
| AWS EC2 Modification | 🟢 Practiced |
| EC2 Instance Type Change | 🟢 Practiced |
| AWS CLI | 🟢 Practiced |
| Subnet Creation | 🟢 Practiced |
| CIDR Planning | 🟢 Practiced |
| Subnet Inspection | 🟢 Practiced |
| Subnet Attribute Modification | 🟢 Practiced |
| Public IP Security Considerations | 🟢 Learned |
| Subnet Deletion | 🟢 Practiced |

**Overall: 🟢 Day 7/100 — Completed**

> **Major realization:** Understanding a cloud or DevOps concept is only the beginning. Troubleshooting the configuration, understanding why it failed, and knowing how to manage the resource through the CLI is what turns the concept into practical knowledge.
````
