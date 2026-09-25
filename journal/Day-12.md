# 📔 Day 12 — Journal Entry

> **Tracks:** 100 Days DevOps · 100 Days Cloud · Linux L1

---

## 🛠️ 100 Days DevOps

**Task:** Troubleshoot an Apache server and make sure it's accessible from outside the app server.

**What I found:**

1. Ran `systemctl status httpd` — the service was down.
2. Discovered that a **different service (sendmail) was using the intended port**, preventing httpd from starting.
3. Stopped the offending service:
   ```bash
   sudo systemctl stop sendmail
   sudo systemctl disable sendmail
   ```
4. Started httpd:
   ```bash
   sudo systemctl start httpd
   sudo systemctl enable httpd
   ```
5. Still not accessible from the jump host → **firewall issue**.
6. Checked firewall rules and added a rule to allow incoming traffic on the correct port:
   ```bash
   sudo firewall-cmd --permanent --add-port=<port>/tcp
   sudo firewall-cmd --reload
   ```

**Result:** ✅ Apache reachable from the jump host.

**Lesson:** When a service won't start, check **what's already listening on the port** before assuming it's a config issue. `ss -tlnp | grep <port>` is your first move.

---

## ☁️ 100 Days Cloud (AWS)

**Task:** Attach a volume to an EC2 instance.

**Approach:**

1. Retrieved the instance ID:
   ```bash
   aws ec2 describe-instances \
     --filter "Name=tag:Name,Values=datacenter-ec2" \
     --query "Reservations[].Instances[].InstanceId"
   ```

2. Retrieved the volume ID (using `--filter` and `--query` for efficiency):
   ```bash
   aws ec2 describe-volumes \
     --filter "Name=tag:Name,Values=<volume-name>" \
     --query "Volumes[].VolumeId"
   ```

3. Attached the volume:
   ```bash
   aws ec2 attach-volume \
     --volume-id <vol-id> \
     --instance-id <instance-id> \
     --device /dev/sdf
   ```

**Result:** ✅ Successfully attached.

---

## 📚 Personal Task

Completed **2 tasks** from the Linux L1 track.

---

## 🎯 Day 12 Takeaways

| Lesson | Detail |
|---|---|
| Diagnose before fixing | `ss -tlnp` reveals what's holding the port |
| Port conflicts happen | sendmail can squat on unexpected ports |
| Firewall is a second layer | A service can run but still be unreachable |
| Filter + query again | Same ID-lookup pattern, different resource |
