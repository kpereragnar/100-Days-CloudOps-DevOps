```markdown
# CloudOps / DevOps Journal

## Day 16 — 28 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Configure Nginx Load Balancer for High Availability

The Nautilus production support team noticed increasing traffic and degraded performance on one of their websites. To improve availability and distribute traffic efficiently, the application was being migrated to a high-availability infrastructure in the Stratos DC.

The remaining task was to configure the **LBR (Load Balancer) server**.

### Requirements

- Install **Nginx** on the LBR server if it was not already installed.
- Configure Nginx load balancing using the **HTTP context**.
- Include **all application servers** in the load-balancing configuration.
- Modify only the main Nginx configuration file:
  `/etc/nginx/nginx.conf`
- Do not change the Apache ports already configured on the application servers.
- Ensure Apache is running on all application servers.
- Verify the website through:

```bash
curl http://stlb01:80
```

### What I Worked On

I configured the LBR server to distribute incoming HTTP requests across the available application servers using Nginx.

This task reinforced the relationship between:

**Client → Load Balancer → Application Servers → Apache**

It also emphasized an important infrastructure principle: the load balancer should work with the existing application-server configuration rather than unnecessarily modifying the backend services.

### Key Lesson

Today was mainly about understanding **load balancing and high availability** in a practical environment.

Instead of sending all traffic to a single application server, Nginx can distribute requests across multiple backend servers, helping improve availability and handle increasing traffic.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create an IAM User Using AWS CLI

Today I created an **AWS IAM user using the AWS CLI**.

This was my first time creating an IAM user directly from the command line rather than through the AWS Management Console.

The command used was:

```bash
aws iam create-user --user-name <username>
```

### What I Learned

This was a small task, but it was useful because it reinforced the idea of managing AWS resources through the CLI rather than depending entirely on the console.

It also gave me more practical exposure to **AWS IAM** and command-line resource management.

---

## 3. Personal Docker Task

Today I completed **two additional Docker tasks** from the Docker L1 preparation and also took the **KodeKloud Engineer Docker L1 Certification Assessment**.

This gave me an opportunity to apply the Docker concepts I had been practicing under an assessment environment rather than simply following tutorials.

The assessment involved practical Docker operations such as:

- Container management
- Docker images
- File transfers between containers and hosts
- Docker networks
- Port mapping
- Troubleshooting

### Certification Progress

**Docker L1 Assessment: 80%**

**Passing Score: 60%**

This added another practical milestone to the journey alongside my previous **Linux L1 assessment (86%)**.

---

## Key Takeaways

- 🔄 Nginx can distribute traffic across multiple application servers.
- ⚖️ Load balancing is an important component of high-availability infrastructure.
- 🖥️ Backend application servers can remain on their existing Apache configuration while the load balancer handles incoming traffic.
- ☁️ AWS resources can be managed directly through the AWS CLI.
- 🔐 IAM is an important part of managing access to AWS resources.
- 🐳 Docker knowledge becomes much more useful when applied through practical tasks and troubleshooting.
- 🧩 CloudOps/DevOps is increasingly about understanding how different infrastructure components work together.

---

## Day Status

| Area                     | Status       |
| ------------------------ | ------------ |
| 100 Days of DevOps       | 🟢 Completed |
| 100 Days of Cloud — AWS  | 🟢 Completed |
| Personal Docker Practice | 🟢 Completed |
| Docker L1 Assessment     | 🟢 80%       |
| Linux L1 Assessment      | 🟢 86%       |

### Overall: 🟢 Day 16/100 — Completed

> **Major realization:** Infrastructure components are rarely isolated. Today connected Nginx, load balancing, Apache, application servers, AWS IAM, CLI automation, and Docker into the bigger picture of managing and operating infrastructure.
```

