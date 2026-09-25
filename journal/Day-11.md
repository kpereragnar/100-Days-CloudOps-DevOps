# 📔 Day 11 — Journal Entry

> **Tracks:** 100 Days DevOps · 100 Days Cloud · Linux L1

---

## 🛠️ 100 Days DevOps

**Task:** Install and configure a Tomcat web server on an app server, set a different port, and copy a `ROOT.war` file to the Tomcat directory.

**What happened:**

No issues faced during the installation and configuration of Tomcat.

The only snag was **figuring out where the web file should go**. This was my first time using Tomcat — I'm used to Apache, which serves from `/var/www/html`. I checked the documentation and discovered Tomcat uses:

```
/usr/share/tomcat/webapps
```

**Lesson:** Different web servers have different directory conventions. Don't assume — check the docs.

---

## ☁️ 100 Days Cloud (AWS)

**Task:** Attach an Elastic Network Interface (ENI) to an EC2 instance.

**Approach:**

1. Got the instance ID:
   ```bash
   aws ec2 describe-instances \
     --filter "Name=tag:Name,Values=datacenter-ec2" \
     --query "Reservations[].Instances[].InstanceId"
   ```

2. Retrieved the ENI ID:
   ```bash
   aws ec2 describe-network-interfaces \
     --filter "Name=tag:Name,Values=datacenter-eni" \
     --query "NetworkInterfaces[].NetworkInterfaceId"
   ```

3. Attached the ENI:
   ```bash
   aws ec2 attach-network-interface \
     --network-interface-id <eni-id> \
     --instance-id <instance-id> \
     --device-index 1
   ```

**Result:** ✅ No issues faced.

---

## 📚 Personal Task

Completed **2 tasks** from the Linux L1 track.

---

## 🎯 Day 11 Takeaways

| Lesson | Detail |
|---|---|
| Web server dirs differ | Tomcat → `/usr/share/tomcat/webapps`, Apache → `/var/www/html` |
| Filter + query pattern | `--filter "Name=tag:Name,Values=<name>" --query "<Res>[].<IdField>"` |
| Two-step lookups | Always resolve IDs before running the action command |

