# CloudOps / DevOps Journal

## Day 17 — 29 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Install and Configure PostgreSQL

Today’s DevOps task involved installing and configuring **PostgreSQL**.

The requirements were to:

* Create a PostgreSQL user with a password.
* Create a database.
* Grant the user access to the database.

### Approach

I completed the configuration by accessing the PostgreSQL console using:

```bash
psql
```

From inside the PostgreSQL console, I proceeded with the required database configuration, including creating the user, creating the database, and granting the user access.

### Key Lesson

Today’s task gave me more practical exposure to **database administration** and working directly with PostgreSQL through its command-line console.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create an IAM Group

Today’s AWS task was to create an **IAM group** using the AWS CLI.

I completed the task using:

```bash
aws iam create-group --group-name <group-name>
```

This continued my practice of managing AWS IAM resources directly through the command line.

### Key Lesson

I’m becoming more comfortable using the **AWS CLI** for IAM administration instead of relying solely on the AWS Management Console.

---

## 3. Personal Docker Task

For my personal learning, I continued working through **Docker L2** tasks.

Today I completed two tasks:

### Docker Update Permissions

Worked through a Docker task focused on updating permissions.

### Create a Docker Image From Container

I also completed a task involving creating a **Docker image from an existing container**.

These tasks are helping me move beyond basic Docker container management and become more comfortable with practical Docker administration.

---

## Key Takeaways

* 🐘 Gained more hands-on experience with PostgreSQL administration using `psql`.
* 👤 Created and configured a PostgreSQL user with database access.
* 🗄️ Created a PostgreSQL database and granted user access.
* ☁️ Created an AWS IAM group using the AWS CLI.
* 🐳 Continued progressing through Docker L2 practical tasks.
* 🔧 Practiced Docker permissions and creating images from containers.
* 💻 Continued building confidence with command-line administration across Linux, AWS, databases, and containers.

---

## Day Status

| Area                        | Status       |
| --------------------------- | ------------ |
| 100 Days of DevOps          | 🟢 Completed |
| 100 Days of Cloud — AWS     | 🟢 Completed |
| Personal Docker L2 Practice | 🟢 Completed |
| Docker L2 Tasks Completed   | 🟢 2 Tasks   |

### Overall: 🟢 Day 17/100 — Completed

> **Major realization:** Today’s tasks reinforced that CloudOps and DevOps involve more than just cloud services. Managing databases, IAM, Linux environments, and containers from the command line are all part of operating real infrastructure.
