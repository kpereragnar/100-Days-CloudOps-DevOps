# CloudOps / DevOps Journal

## Day 57 — 8 November 2026

**Challenges:** 100 Days DevOps, K8 L2, and Codomax Internship (Module 05)

> **Context:** K8 L2 officially started today (3 tasks). Also completed the daily 100 Days DevOps task and deployed a serverless API via Terraform for the Codomax internship.

---

## 1. 100 Days DevOps / K8 L2 Task 1 — Deployment & NodePort Service

**Task:** Create `nginx-deployment` (3 replicas, `nginx:latest`, container `nginx-container`) and `nginx-service` (NodePort 30011).

**The Fix:**
Combined both resources into one manifest using `---`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx-container
          image: nginx:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30011
```

### Key Learning
**YAML files can hold multiple resources** as long as they are separated by `---`. The Service `selector` must match the Deployment's pod labels exactly, or the endpoints will be `<none>`.

---

## 2. K8 L2 Task 2 — Shared Volume Pod (`volume-share-devops`)

**Task:** Create a pod with two `ubuntu:latest` containers, sharing an `emptyDir` volume at `/tmp/beta` and `/tmp/games`. Write `beta.txt` in container 1, verify in container 2.

**The Fix:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-devops
spec:
  volumes:
    - name: volume-share
      emptyDir: {}
  containers:
    - name: volume-container-devops-1
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "sleep infinity"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/beta
    - name: volume-container-devops-2
      image: ubuntu:latest
      command: ["/bin/sh", "-c", "sleep infinity"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/games
```

### Key Learning
**`emptyDir` is shared at the Pod level.** Different containers can mount it at different paths, but they point to the same underlying directory on the node. `sleep infinity` keeps the `ubuntu` containers alive so you can `exec` into them.

---

## 3. K8 L2 Task 3 — Native Sidecar (`webserver`)

**Task:** Create `webserver` pod. Main container `nginx-container` (`nginx:latest`), sidecar `sidecar-container` (`ubuntu:latest`) as a native sidecar with `restartPolicy: Always` inside `initContainers`. Shared `emptyDir` at `/var/log/nginx`.

**The Fix:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}
  initContainers:
    - name: sidecar-container
      image: ubuntu:latest
      restartPolicy: Always
      command: ["sh", "-c", "while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx
  containers:
    - name: nginx-container
      image: nginx:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx
```

### Key Learning
**Kubernetes 1.28+ native sidecars** belong in `initContainers` with `restartPolicy: Always`. This tells K8s to start them first (so they can catch logs immediately) but keep them running for the entire life of the Pod. 

---

## 4. Codomax Internship — Module 05: AWS Lambda & Serverless

**Task:** Build a simple serverless API using AWS Lambda and API Gateway via Terraform.

### What I Built
- **Lambda Function (`index.py`)**: A Python function returning a JSON payload (`{"message": "Hello from Codomax Serverless API!"}`).
- **Terraform Infrastructure**: Used `archive_file` to automatically zip the Python code, created an IAM execution role, deployed the Lambda function, set up an API Gateway HTTP API, and routed `GET /hello` to the Lambda.

**The Terraform snippet for the Lambda:**
```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "api_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.project_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}
```

### Issues Faced and How I Fixed Them

**Issue: `AccessDeniedException` on Lambda and API Gateway.**
When running `terraform apply` in my personal AWS account, it failed because the `user/Kpere` IAM user didn't have permissions to create Lambda functions or API Gateways. (KodeKloud labs give you full admin credentials; personal accounts don't).

**Fix:** Logged into the AWS Console, attached the `AWSLambda_FullAccess` and `AmazonAPIGatewayAdministrator` policies to the `Kpere` user. Re-ran `terraform apply`, and it succeeded.

**Verification:**
```bash
curl -s <api-gateway-url>/hello
# → {"message": "Hello from Codomax Serverless API!", "status": "Success"}
```

### Key Learning
**Terraform's `archive_file` data source is a game-changer.** Instead of manually running `zip` and managing file hashes, Terraform zips the source code and computes the hash automatically. Every time you change the Python code and run `terraform apply`, it detects the new hash and redeploys the Lambda.

**IAM permissions in personal accounts are strict.** Unlike labs, you have to explicitly grant your user permissions for every new service you touch.

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 | 🟢 Started (3 tasks done) |
| **Codomax Internship** | Nov 8 | 🟢 Module 05 (Lambda) Completed |
| **Terraform L2** | Paused at 5/20 | Resumes after K8 L2 or alternates |

---

## Key Takeaways
- 🐳 **Multi-resource YAML** uses `---` to separate Deployments and Services.
- 🐳 **`emptyDir` volumes** are shared across all containers in a Pod.
- 🐳 **Native sidecars (K8s 1.28+)** use `initContainers` with `restartPolicy: Always`.
- ☁️ **Terraform `archive_file`** automates zipping Lambda source code.
- ☁️ **Personal AWS accounts** require explicit IAM policies for every service (unlike labs).

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Deployment | 🟢 Completed |
| K8 L2 — Shared Volume | 🟢 Completed |
| K8 L2 — Native Sidecar | 🟢 Completed |
| Codomax — Module 05 (Lambda) | 🟢 Completed |

**Overall: 🟢 Day 57/100 — Completed**

> **Realization:** Today was a beautiful collision of the same concepts across different platforms. In Kubernetes, the sidecar pattern uses `emptyDir` volumes to ship logs. In AWS, serverless functions require an execution role to interact with other services. Both are about *wiring components together correctly*. 
> 
> The `AccessDeniedException` on the Lambda was a humbling reminder that lab environments coddle you. Moving to a personal AWS account means owning the IAM permissions, understanding the blast radius of what you're building, and fixing it when the cloud says "no."
> 
> K8 L2 has started with the exact patterns that K8 L1 ended with, but with more moving parts. The difficulty curve is ramping up, but the tools and debugging instincts are transferring perfectly.
