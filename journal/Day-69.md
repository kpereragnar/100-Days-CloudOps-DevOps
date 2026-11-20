Here is the journal entry for today (Day 69). This one is special because it marks the moment you started operating as an independent engineer. 

---

# CloudOps / DevOps Journal

## Day 69 — 20 November 2026

**Challenges:** Jenkins Installation & Terraform L2

> **Context:** A major milestone in independence. Today, I completed both the Jenkins CI server setup and a Terraform SNS/SQS messaging task entirely on my own, without needing a step-by-step walkthrough. The training wheels are officially off.

---

## 1. Jenkins CI Server Installation

**Task:** Install Jenkins on an Ubuntu server (no systemd) using `apt`, start it with `service`, and configure the admin user (`theadmin` / `Adm!n321` / John).

**What I Did:**
Since I had already completed the Jenkins L1 track, the terminal muscle memory was there. I bypassed the need for a guide and executed the standard sequence:
1. Installed Java 21 (`openjdk-21-jre`) using `apt`.
2. Added the Jenkins GPG key and Debian repository.
3. Installed Jenkins via `apt`.
4. Started the service using `service jenkins start` (correctly avoiding `systemctl`, which fails in this container environment).
5. Retrieved the initial admin password from `/var/lib/jenkins/secrets/initialAdminPassword`.
6. Opened the UI, installed the suggested plugins, and created the exact admin user requested.

### Key Learning
**Foundation tracks pay off.** Because I had spent time in the Jenkins UI during L1, setting up the admin user and plugins felt like second nature. 
**The `service` vs `systemctl` trap:** In environments without systemd (like some Docker containers), `systemctl` will fail with "System has not been booted with systemd." Using `service` is the correct fallback. Also, Jenkins is heavily dependent on the Java version; installing Java 21 first prevents the service from hanging on startup.

---

## 2. Terraform L2 — AWS SNS & SQS Messaging

**Task:** Create an SNS topic (`nautilus-sns-topic`), an SQS queue (`nautilus-sqs-queue`), and subscribe the queue to the topic. Output the SNS ARN and SQS URL.

**What I Did:**
I wrote the Terraform configuration entirely from memory, structuring the provider, resources, and outputs. 

The initial skeleton was correct:
```hcl
resource "aws_sns_topic" "topic" {
  name = "nautilus-sns-topic"
}

resource "aws_sqs_queue" "queue" {
  name = "nautilus-sqs-queue"
}

resource "aws_sns_topic_subscription" "sub" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}
```

**The Catch (The Hidden Requirement):**
I remembered the security lesson from previous IAM tasks: **AWS resources do not trust each other by default.** SNS cannot drop messages into an SQS queue unless the queue explicitly allows it. I added the `aws_sqs_queue_policy`.

```hcl
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.queue.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.topic.arn }
      }
    }]
  })
}
```

### Key Learning
**Resource creation is only half the battle; wiring them together securely is the other half.** Without the queue policy, the subscription would exist, but every message SNS sent would be silently dropped by SQS with an `AccessDenied`.

**The `SourceArn` condition is critical.** It ensures that *only* my specific SNS topic can send messages to the queue, preventing other AWS accounts from injecting messages. This is the textbook "confused deputy" security pattern.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1 & L2** | Nov 6 – Nov 19 | ✅ Completed |
| **Terraform L2** | Nov 14 – Present | 🟢 In Progress |
| **Acumen Internship** | Nov 23 | Starts in 3 days |

---

## Key Takeaways
- ⚙️ **Use `service` instead of `systemctl`** when working in environments without a systemd init process.
- 🔧 **SNS → SQS requires a Queue Policy.** The queue must explicitly grant `sqs:SendMessage` to `sns.amazonaws.com`.
- 🔧 **Use `Condition: aws:SourceArn`** to restrict queue access to only your specific SNS topic.
- 🧠 **Independence achieved:** Completing both tasks solo proves that the daily repetition has successfully built the mental models required to architect and deploy without hand-holding.

---

## Day Status
| Area | Status |
|---|---|
| Jenkins Installation | 🟢 Completed |
| Terraform L2 — SNS/SQS | 🟢 Completed |

**Overall: 🟢 Day 69/100 — Completed**

> **Realization:** Today felt different. When I read the task prompts, I didn't feel the usual anxiety of "how do I start this?" I just started typing. The Jenkins `apt` commands flowed naturally. The Terraform SNS and SQS resources were written without having to look up the syntax. I even anticipated the hidden trap (the missing queue policy) because I remembered the IAM trust policy and EIP association lessons from previous weeks. 
>
> The last 69 days have been a massive exercise in repetition and pattern recognition. I've written hundreds of resource blocks, hit dozens of errors, and debugged everything from Kubernetes volume mounts to Terraform state drift. Today proved that the knowledge has shifted from "remembering commands" to "engineering solutions." The training wheels are off.
