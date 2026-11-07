---

# CloudOps / DevOps Journal

## Day 56 — 7 November 2026

**Challenges:** Codomax Internship (Module 03) & 100 Days DevOps

> **Context:** Shifted focus to the Codomax AWS Cloud/DevOps internship to complete Module 03 on Amazon S3. Deployed a static portfolio website using Terraform.

---

## 1. Codomax Internship — Module 03: Amazon S3 & Static Website Hosting

**Task:** Understand S3 fundamentals, provision a bucket with Terraform, manage objects, implement access controls, and deploy a publicly accessible static portfolio website.

### What I Built

**1. S3 Bucket Provisioning with Terraform**
- Created an S3 bucket named `codomax-s3-training-kpere-2026`.
- Configured AWS provider settings (`us-east-1`) and applied resource tags for project identification.

**2. S3 Bucket Configuration**
- Enabled bucket versioning to maintain multiple versions of stored objects.
- Configured AES-256 server-side encryption for data protection.
- Implemented bucket ownership controls using `BucketOwnerEnforced`.
- Configured S3 Block Public Access settings to support controlled public website access.

**3. S3 Object Management**
- Created and uploaded website files: `index.html`, `error.html`, `style.css`.
- Used Terraform's `aws_s3_object` resource to manage the uploaded files.
- Configured appropriate content types for HTML and CSS files.

**4. S3 Access Control**
- Created an S3 bucket policy using Terraform and `jsonencode()`.
- Granted public read-only access through `s3:GetObject`.
- Kept public ACLs disabled while using a bucket policy to control access.
- Learned how S3 Block Public Access settings interact with bucket policies.

**5. Static Website Hosting**
- Enabled S3 static website hosting.
- Configured `index.html` as the default document and `error.html` as the error document.
- Deployed a personal portfolio website highlighting my interests and skills in Cybersecurity, Cloud Computing, and DevOps.

**Website URL:** `http://codomax-s3-training-kpere-2026.s3-website-us-east-1.amazonaws.com`

---

### Key Lessons Learned

- **Buckets vs. Objects:** Understanding the difference between the container (bucket) and the files (objects) is foundational.
- **Versioning & Encryption:** How versioning helps preserve previous object versions and how server-side encryption protects stored data at rest.
- **Access Control:** How bucket policies and Block Public Access settings work together. (Modern S3 relies on policies, not ACLs).
- **IaC Automation:** How Terraform can automate S3 infrastructure provisioning, configuration, and object uploads.
- **Static Hosting limits:** S3 static website endpoints support HTTP, not HTTPS. To add HTTPS, I need to put Amazon CloudFront in front of the bucket.

---

## 2. 100 Days DevOps — Daily Task

*(Note: If you completed a K8 task today, drop the YAML/commands here. If today was strictly focused on the internship, you can remove this section or note that you took a break from K8 today to focus on the internship).*

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **Codomax Internship** | Nov 7 | ✅ Module 03 (S3) Completed |
| **K8 L2** | Tomorrow (Nov 8) | Starts |
| **Terraform L2** | Paused at 5/20 | Resumes after K8 L2 or alternates |

---

## Key Takeaways

- ☁️ **S3 static websites need specific config:** Turn off Block Public Access, attach a bucket policy for `s3:GetObject`, and enable the website configuration.
- ☁️ **Terraform S3 Structure:** The `aws_s3_bucket` resource is just the container. You need separate resources for versioning, encryption, ownership, public access, policy, and website config.
- ☁️ **HTTPS requires CloudFront.** The `s3-website-us-east-1.amazonaws.com` endpoint is HTTP-only. 
- ☁️ **`jsonencode()`** is the cleanest way to attach IAM/Bucket policies in Terraform.

---

## Day Status

| Area | Status |
|---|---|
| Codomax Internship — Module 03 | 🟢 Completed |
| 100 Days DevOps | 🟢 Completed |

**Overall: 🟢 Day 56/100 — Completed**

> **Realization:** Deploying an S3 bucket via the Console takes 2 minutes. Deploying it via Terraform forces you to understand exactly how many moving parts are involved. S3 is no longer just "create bucket, upload file." It's versioning, encryption, ownership controls, public access blocks, bucket policies, website configs, and object uploads—all managed by separate Terraform resources. 
> 
> Tomorrow, the focus shifts back to Kubernetes as K8 L2 begins. Terraform L2 remains paused at 5/20, but the S3 work today kept the Terraform skills sharp.
