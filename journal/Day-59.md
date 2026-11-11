# CloudOps / DevOps Journal

## Day 59 — 10 November 2026

**Challenges:** 100 Days DevOps & K8 L2

> **Context:** Deployed Grafana via a Deployment and NodePort Service. Hit a 502 Bad Gateway due to a port mismatch between the lab's internal router and the K8s Service, but resolved it.

---

## 1. 100 Days DevOps / K8 L2 — Grafana Deployment & NodePort

**Task:** Create a Deployment `grafana-deployment-datacenter` using any Grafana image, and a NodePort Service on port `32000` to expose the login page.

**The Manifest:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-deployment-datacenter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:latest
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 32000
EOF
```

### Issues Faced and How I Fixed Them

**Issue 1 — 502 Bad Gateway on the App Button:**
The deployment and service were perfectly healthy. `kubectl get endpoints` showed the pod IP, and `curl -I http://localhost:32000` returned `HTTP/1.1 302 Found` (the Grafana login redirect). 

**Root cause:** The KodeKloud "App" button uses an internal Ingress/LoadBalancer that is hardcoded to look at **port 80** on the Service. Because the Service exposed port `3000` externally, the lab's router couldn't reach it.

**Issue 2 — `kubectl patch` failed with `duplicate nodePort`:**
I tried to patch the Service to change the external port from 3000 to 80, but Kubernetes rejected it because port `32000` was already registered to the old configuration.

**Fix:** 
I deleted the Service and recreated it with the correct port mapping (`port: 80`, `targetPort: 3000`, `nodePort: 32000`):
```bash
kubectl delete svc grafana-service
kubectl apply -f /tmp/grafana-svc.yaml
```

### Key Learning

**The KodeKloud "App" button expects port 80.** Even if your application internally listens on port 3000 (like Grafana) or 8080, the lab's reverse proxy looks for a Kubernetes Service exposing `port: 80`. If you get a 502 on a NodePort task, check the Service's `port` field first.

**You cannot patch a NodePort if the new config conflicts with the old one.** Kubernetes allocates NodePorts strictly. If you need to change the port mapping, the safest route is always `delete` + `apply`. 

---

## Timeline & Next Steps

| Track | Date | Status |
|---|---|---|
| **100 Days Cloud (AWS)** | Nov 3 | ✅ Certified |
| **K8 L1** | Nov 6 | ✅ Certified (99%) |
| **K8 L2** | Nov 8 | 🟢 In Progress |
| **100 Days DevOps** | Ongoing | K8 Block |
| **Codomax Internship** | Nov 8 | Module 05 (Lambda) Completed |

---

## Key Takeaways
- 🐳 **Grafana's default port is 3000**, not 80. You must map it correctly in the container spec and Service targetPort.
- 🐳 **502 Bad Gateway on a NodePort usually means the Service's external `port` doesn't match what the proxy expects (usually 80).**
- 🐳 **`kubectl patch` fails on NodePort conflicts.** `delete` and `apply` is the clean fix.
- 🐳 **Always test NodePorts with `curl`** from the jump-host to isolate whether the issue is your YAML or the KodeKloud web button.

---

## Day Status
| Area | Status |
|---|---|
| 100 Days DevOps — Grafana | 🟢 Completed |
| K8 L2 — Grafana | 🟢 Completed |

**Overall: 🟢 Day 59/100 — Completed**

> **Realization:** Grafana itself wasn't the hard part. The hardest part was understanding the invisible layer between the Kubernetes cluster and the KodeKloud web UI. The lesson here is that "the app works" (proven by `curl`) and "the platform can access the app" (proven by the App button) are two different layers of troubleshooting. Once I aligned the Service's external port to what the platform router expected, everything clicked.
