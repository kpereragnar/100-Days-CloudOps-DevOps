# 📊 Weekly Recap — Days 57–63

![Week 9](https://img.shields.io/badge/Week-9-blue) ![Days 57–63](https://img.shields.io/badge/Days-57--63-green) ![Status](https://img.shields.io/badge/Status-Completed-brightgreen) ![Track](https://img.shields.io/badge/Track-CloudOps%20%2F%20DevOps-purple)

## 🗓️ Week 9: Days 57–63

> **The Kubernetes L2 Gauntlet & My First CI/CD Pipeline.**

Week 9 was a significant milestone in my DevOps learning journey. I completed the Kubernetes L2 track, tackled several challenging application and infrastructure troubleshooting exercises, progressed with Terraform L2, and delivered two important internship assessment projects.

The most significant achievement was building my first CI/CD pipeline from scratch for the **Springer Capital DevOps Internship Assessment**. The project combined Docker, GitHub Actions, GitHub Container Registry, HashiCorp Nomad, Consul, Loki, Promtail and Grafana. It was subsequently approved.

I also completed the AWS Lambda and API Gateway module for the **Codomax Digital Solutions Internship**.

**Topics covered:** Kubernetes Deployments, Services, PersistentVolumes, PersistentVolumeClaims, Init Containers, Secrets, LAMP Stack Troubleshooting, Redis Troubleshooting, AWS Lambda, API Gateway, GitHub Actions, Docker, Nomad, Consul, Grafana/Loki Observability and Terraform AMI Provisioning.

> 🔑 **Theme of the week:** *Running does not necessarily mean working.* Infrastructure can report a healthy state while the application itself remains broken. Proper engineering requires validating the actual service, investigating logs and understanding the entire application stack.

---

## 📅 Daily Summary

| Day | 100 Days DevOps / K8 L2 | Internship Assessments / Terraform |
|---|---|---|
| **57** | Started Kubernetes L2: Deployments, Shared Volumes and Native Sidecars | Codomax Module 05: AWS Lambda & API Gateway |
| **58** | Environment Variables Pod: `print-envars-greeting` | — |
| **59** | Grafana Deployment and troubleshooting a 502 port issue | — |
| **60** | Redis troubleshooting, HTTPD Rollback, Jenkins, Tomcat and Node.js application tasks | — |
| **61** | Kubernetes Storage: PV, PVC, Pods and Services; Redis troubleshooting | — |
| **62** | Init Containers and final Kubernetes L2 task: LAMP Stack Troubleshooting | Kubernetes L2 track completed |
| **63** | Kubernetes Secrets and Volumes | Terraform L2 resumed: AMI creation and syntax troubleshooting |

---

## 🎯 Three Major Achievements

### 1. Kubernetes L2 Track Completed

This was one of the most technically demanding parts of the week.

I completed over 15 Kubernetes L2 tasks, covering:

- Deployments and application workload management.
- NodePort Services and service connectivity.
- Shared volumes and persistent storage.
- PersistentVolumes (PV) and PersistentVolumeClaims (PVC).
- Init Containers and Native Sidecars.
- Kubernetes Secrets and environment variables.
- Multi-container application troubleshooting.
- LAMP stack deployment and debugging.

The final LAMP troubleshooting exercise reinforced the importance of investigating application-level failures rather than assuming every problem originates from Kubernetes infrastructure.

### 2. First CI/CD Pipeline — Springer Capital Assessment

A major personal milestone: I built my first CI/CD pipeline from scratch for the Springer Capital DevOps Internship Assessment.

The project involved:

**Containerisation**
- Built a lightweight NGINX Docker image using Alpine.
- Implemented non-root container execution.
- Added a health endpoint and Docker HEALTHCHECK.

**Continuous Integration**
- Developed a GitHub Actions workflow.
- Integrated ShellCheck for shell script validation.
- Integrated Hadolint for Dockerfile linting.
- Automated Docker image building and validation.

**Container Registry**
- Configured GitHub Container Registry (GHCR).
- Automated image publishing.
- Implemented commit-specific SHA tags and a `latest` tag.

**Orchestration and Service Discovery**
- Created a HashiCorp Nomad job specification.
- Configured Docker-based workloads, resource constraints and dynamic port allocation.
- Implemented deployment update, restart and rescheduling policies.
- Integrated Consul for service registration and HTTP health checks.

**Observability**
- Configured Loki and Promtail for centralised log collection.
- Integrated Grafana for log querying and monitoring.

**Version Control**
- Merged three pull requests.
- Created and pushed an annotated `v1.0.0` release tag.

<PRIVATE_NOTE> </PRIVATE_NOTE>

**Outcome:** The project was submitted and approved as the Springer Capital CI/CD assessment.

An important architectural distinction: GitHub Actions automated validation, image building and publishing to GHCR. Nomad deployment was configured separately; the workflow did not automatically deploy every newly published image.

### 3. Codomax AWS Serverless Assessment & Terraform L2

For the Codomax Digital Solutions internship, I completed the AWS Lambda and API Gateway module, building a simple serverless API.

I also resumed the Terraform L2 track, exploring custom Amazon Machine Image creation and resource references.

Key Terraform concepts revisited:

- `aws_ami_from_instance` for creating an AMI from an existing EC2 instance.
- Resource attributes and references.
- Input variables versus resource references.
- Implicit dependencies between Terraform resources.
- Correct Terraform configuration syntax.

This helped reinforce the relationship between infrastructure resources, their attributes and Terraform's dependency management.

---

## 🔥 Hardest Moments & Technical Lessons

### 1. The Redis Troubleshooting Chain — Day 60–61

This was a good example of how one application failure can conceal several independent infrastructure problems.

The troubleshooting process uncovered multiple issues:

- A ConfigMap naming error (`redis-conig` instead of `redis-config`) caused the container to remain in `ContainerCreating`.
- After correcting the configuration reference, an invalid image tag caused `ImagePullBackOff`.
- The subsequent rollout exposed an old ReplicaSet that was interfering with the expected deployment state.

**What I learned:** Kubernetes troubleshooting should be systematic. Fixing the first visible error does not guarantee that the application will become healthy. Configuration, image availability, workload state and rollout history must all be examined.

### 2. The LAMP Stack Application Failure — Day 62

One of the most interesting troubleshooting exercises of the week.

The Kubernetes environment appeared healthy, with both containers reporting `2/2 Running`. However, the PHP application still failed to connect to its database.

After examining the application code, I discovered two incorrect environment variable references:

```php
$dbpass = $_ENV['MYSQL_PASSWORDS'];
$dbhost = $_ENV['HOST_MYQSL'];
```

The problems were an extra `S` in `MYSQL_PASSWORDS` and a transposed character in `HOST_MYQSL`.

I corrected the references using `sed` inside the running container.

**What I learned:** A healthy Pod does not automatically mean a healthy application. Application configuration, environment variables and database connectivity must be validated independently of Kubernetes workload status.

### 3. Grafana's 502 Bad Gateway — Day 59

Deploying Grafana was not simply a matter of getting the Pod to run. The application also needed to be accessible through the expected service configuration.

The 502 error required investigating the relationship between the application port, Kubernetes Service configuration and the access mechanism.

**What I learned:** Successful deployment and successful access are two different things. Service ports, target ports, selectors and application listening ports must align.

### 4. Terraform Resource References — Day 63

While resuming Terraform L2, I encountered errors caused by incorrect resource attribute references.

Two important corrections were:

- `aws_instance.ec2.instance_id` versus `aws_instance.ec2.id`.
- `var.aws_instance` versus referencing an actual resource directly.

**What I learned:** Terraform distinguishes between input variables, resources and resource attributes. Understanding these references is fundamental to building reliable infrastructure configurations.

---

## 🧠 Skills Sharpened

| Technical Area | Skills and Concepts |
|---|---|
| Kubernetes | Deployments, NodePorts, PVs, PVCs, Secrets, Init Containers and Sidecars |
| Kubernetes Troubleshooting | ContainerCreating, ImagePullBackOff, 502 errors, rollout and application debugging |
| CI/CD | GitHub Actions, ShellCheck, Hadolint, Docker builds and GHCR publishing |
| Containerisation | Docker, Alpine images, non-root execution and health checks |
| Orchestration | HashiCorp Nomad and job specifications |
| Service Discovery | Consul registration and health checks |
| Observability | Grafana, Loki and Promtail |
| AWS | Lambda and API Gateway |
| Terraform | AMI creation, resource references and implicit dependencies |
| Version Control | Git, GitHub, pull requests and annotated release tags |

---

## 🏅 Learning Progress & Project Milestones

| Learning Track / Project | Status |
|---|---|
| 100 Days of Cloud (AWS) | 100% completed |
| Kubernetes L1 | 99% |
| **Kubernetes L2** | **Completed** |
| Terraform L2 | Resumed |
| **NGINX CI/CD & Nomad Project — Springer Capital** | **Approved** |
| AWS Lambda & API Gateway — Codomax | Completed |

---

## 🎓 Five Lessons That Stuck

1. **Running is not the same as working.** A Pod can report `2/2 Running` while the application inside it is broken. Always test the actual application endpoint and inspect its logs.

2. **Kubernetes storage requires correct configuration and binding.** PersistentVolumes and PersistentVolumeClaims must satisfy compatible storage requirements before workloads can use them.

3. **A 502 error is not necessarily an application crash.** Service selectors, port mappings, target ports and the application's listening port all matter.

4. **CI/CD pipelines need quality gates.** ShellCheck, Hadolint and Docker build validation help identify problems before container images are published.

5. **Terraform references have distinct meanings.** `var.` references input variables, while resource references use the resource type and name, followed by the required attribute.

---

## 📊 Week in Numbers

| Metric | Achievement |
|---|---|
| Learning days completed | 7 |
| Kubernetes L2 | Completed |
| Terraform L2 | Resumed |
| First CI/CD pipeline | Built and approved |
| Internship assessment projects | 2 |
| Pull requests merged | 3 |
| Git release tags | `v1.0.0` |
| Major troubleshooting exercises | Redis, LAMP, Grafana and Terraform |

---

## 🎯 Focus for Next Week — Days 64–70

- **Terraform L2:** Continue with modules, workspaces, `for_each` and lifecycle rules.
- **100 Days DevOps:** Continue the Kubernetes and infrastructure learning tracks.
- **Acumen Strategy / Springer Capital:** Prepare for the next internship phase scheduled to begin on 23 November 2026.
- **Portfolio Development:** Document and showcase the NGINX CI/CD and AWS PrestaShop deployment projects.
- **Practical Reinforcement:** Revisit the Kubernetes troubleshooting exercises and Terraform configurations without relying solely on guided solutions.

---

## 💡 Week 9 Major Realisation

> **I am moving beyond learning how infrastructure works to understanding how applications are built, delivered, operated and monitored.**

The Kubernetes exercises taught me how to deploy and troubleshoot workloads. The Terraform exercises strengthened my understanding of infrastructure provisioning. The NGINX project brought several of these concepts together into a practical engineering workflow.

Building my first CI/CD pipeline for Springer Capital was particularly significant. It gave me hands-on experience connecting source control, automated validation, container image building, registry publishing, orchestration, service discovery and observability.

The biggest takeaway is that DevOps engineering is not about knowing individual tools in isolation. It is about understanding how these tools work together to deliver reliable and maintainable systems.

---

## ✅ Overall: Week 9 — Days 57–63 Completed

**Kubernetes L2 Completed · First CI/CD Pipeline Built and Approved · Codomax Serverless Assessment Completed · Terraform L2 Resumed**
