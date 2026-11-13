---

# 📊 Weekly Recap — Days 50–56

[![Week](https://img.shields.io/badge/week-8-blue)](#)
[![Days](https://img.shields.io/badge/days-50--56-green)](#)
[![Status](https://img.shields.io/badge/status-completed-brightgreen)](#)
[![Track](https://img.shields.io/badge/track-CloudOps%20%2F%20DevOps-purple)](#)

## 🗓️ Week 8: Days 50–56

> **The AWS Milestone & The K8 L1 Gauntlet.** The week started with a frustrating failure in an AWS lab, but quickly pivoted into a massive high: completing the 100 Days of Cloud (AWS) Certification. The week ended with the final, brutal push to clear the K8 L1 track, capped off with a 99% assessment score.

Covered: **100 Days Cloud Certification, K8 L1 (Jobs, CronJobs, Rollbacks, Sidecar troubleshooting, Volume Mounts), K8 L1 Assessment, and the start of the Codomax Internship.**

> 🔑 **Theme of the week:** *Reading the exact error message is 90% of the fix.* Whether it was an SSH jump host failing, a ConfigMap typo, or a K8s grader rejecting the modern `initContainers` syntax, the answer was always in the terminal output.

---

## 📅 Daily Summary

| Day | 100 Days DevOps | K8 L1 Track | Codomax / Other |
|---|---|---|---|
| **50** | Log Aggregation Lab (Failed) | Started K8 block | — |
| **51** | K8 Pods & Namespaces | Rolling Update, Revert Version | — |
| **52** | K8 Job & CronJob | Sidecar failure (Init vs Container) | **🏆 100 Days Cloud (AWS) Certified** |
| **53** | — | Sidecar battle continues | — |
| **54** | VolumeMounts (Nginx+PHP) | **Sidecar Victory**, Update Deploy, Expose RS | **K8 L1 Track Complete** |
| **55** | Shared Volume Pod | **K8 L1 Assessment: 99% Passed** | — |
| **56** | — | — | **Codomax Internship:** Module 03 (S3) |

---

## 🎯 Three Big Themes

### 1. The 100 Days Cloud Milestone
On Day 52, you officially completed the AWS track of the 100 Days of Cloud. You made the strategic decision to skip the Azure half to focus on building deep AWS expertise rather than shallow multi-cloud knowledge. This freed up mental bandwidth for the Kubernetes push.

### 2. The K8 L1 Gauntlet (Sidecars & Volume Mounts)
K8 L1 ended with some of its hardest tasks. You spent days fighting the `webserver` sidecar task because the automated grader rejected the modern K8s 1.28 `initContainers` feature and demanded the older `spec.containers` layout. You also debugged the `nginx-phpfpm` task, learning that a 502 Bad Gateway is almost always a missing label or an empty Service endpoint. 

### 3. The K8 L1 Assessment (99%)
The week culminated in a live cluster assessment. You cleared 9/10 questions, proving that the debugging instincts you built during the week (patching services, fixing labels, finding missing endpoints) actually stuck. The only miss was a formatting issue on `command` vs `args`, not a knowledge gap.

---

## 🔥 Hardest Moments

**The Log Aggregation Lab (Day 50).** An AWS task involving VPC peering and cross-instance SCP failed repeatedly. The SSH jump host kept dropping the connection (`port 65535`), and the private subnet's effective route table wasn't what the task described. It was a painful failure, but it proved the plan could absorb interruptions.

**The Native Sidecar (Days 52–54).** The K8 L1 grader demanded a sidecar, but refused the `initContainers` method. You had to pivot to `tail -f /dev/null` inside `spec.containers` to pass the regex check.

**K8 L1 Q1 (Day 55).** The only failure on the assessment. You split the command and args (`command: ['/bin/bash', '-c']`, `args: ['sleep 1000']`), but the grader wanted the whole string inside `command`.

---

## 🧠 Skills Sharpened

| Area | Growth |
|---|---|
| **Certifications** | 100 Days Cloud (AWS) completed, K8 L1 completed |
| **K8 L1 (Workloads)** | Jobs, CronJobs, ReplicaSets, Deployments, Sidecars |
| **K8 L1 (Networking)** | NodePort Services, Service Selectors, Endpoints |
| **K8 L1 (Storage)** | `emptyDir` shared volumes, VolumeMounts |
| **K8 L1 (Troubleshooting)** | `describe pod`, reading Events, fixing 502s |
| **Codomax Internship** | Terraform S3 static website (Module 03) |

---

## 🏅 Certifications

| Badge | Status |
|---|---|
| 🐧 Jenkins L1 | 100% ✅ |
| ⚙️ Ansible L1 & L2 | 100% ✅ |
| 🌿 Git L1 | 100% ✅ |
| 🐧 Linux L1 | 86% ✅ |
| 🐳 Docker L1 & L2 | 100% ✅ |
| 🔧 Terraform L1 | 75% ✅ |
| ☁️ **100 Days of Cloud (AWS)** | **100% ✅** |
| **☸️ Kubernetes L1** | **99% ✅** |

---

## 🎓 Five Lessons That Stuck

1. **The Grader is Not the Real World.** Native sidecars (`initContainers`) are the K8s 1.28+ standard, but automated graders often want the older `spec.containers` syntax. Read the exact wording of the task.
2. **`command` vs `args` in K8s.** Unless the prompt specifically separates them, put the whole execution string into the `command` array to satisfy automated checks.
3. **502 Bad Gateway = Empty Endpoints.** When a KodeKloud App button throws a 502, run `kubectl get endpoints`. If it says `<none>`, the Service selector doesn't match the Pod labels.
4. **Recreating a Pod wipes its labels.** If you delete and recreate a pod to fix a volume mount, you must re-apply the labels or the Service will lose its connection to the app.
5. **The plan absorbs failures.** The failed AWS lab on Day 50 didn't derail the 100 Days Cloud cert on Day 52. Pivot, keep moving, and protect the milestones.

---

## 📊 Week in Numbers

| Metric | Count |
|---|---|
| Days completed | 7 |
| Certifications earned | 2 (AWS Cloud, K8 L1) |
| K8 L1 Assessment Score | 99% |
| Tasks Passed | ~15 (Labs + K8) |
| Failed Labs | 1 (AWS Log Aggregation) |
| Sidecar Grader Attempts | 4 |

---

## 🎯 Focus for Next Week (Days 57–63)

*   ☸️ **K8 L2 deep dive** — Deployments, NodePorts, Rolling Updates, and PV/PVC.
*   ☁️ **Codomax Internship** — Module 05 (AWS Lambda & API Gateway).
*   🔧 **Terraform L2** — Paused at 5/20; need to integrate it back into the schedule.
*   📝 **Keep the journal honest** — recording the failures is just as important as the wins.

---

## 💡 Week 8 Major Realization

> **The exam is not the skill; the debugging is the skill.**
> 
> You didn't pass K8 L1 with 99% because you memorized YAML. You passed because you knew how to check endpoints, read pod descriptions, and fix missing labels. The `nginx-phpfpm` task and the sidecar task forced you to look at the invisible layers of Kubernetes—Service selectors, volume mounts, and container lifecycles.
> 
> When you got to the assessment, the questions weren't asking "what is the syntax?" They were asking "how do you fix this?" And you knew how, because you'd spent the week breaking and fixing those exact things.
> 
> **The certificate is a summary. The debugging is the actual education.**

---

<div align="center">

## ✅ Overall: 🟢 Week 8 — Days 50–56 Completed

**100 Days Cloud Certified · K8 L1 Certified (99%) · Codomax Internship Continued**

</div>
