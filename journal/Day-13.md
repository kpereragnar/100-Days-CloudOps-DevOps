# 📔 Day 13 — Journal Entry

> **Tracks:** 100 Days DevOps · 100 Days Cloud · Linux L1

---

## 🛠️ 100 Days DevOps

### Task

One of our websites is up and running on the **Nautilus** infrastructure in **Stratos DC**. The security team flagged that **Apache's port `3003` is open to everyone** because there is no firewall installed on these hosts.

**Requirements:**

1. Install `iptables` and all its dependencies on each app host.
2. Block incoming port `3003` on all apps **for everyone except the LBR host**.
3. Ensure the rules remain **after system reboot**.

### What I did

**On App Server 1:**

1. Installed iptables:
   ```bash
   sudo yum install -y iptables-services
   ```

2. Enabled and started the service:
   ```bash
   sudo systemctl enable --now iptables
   ```

3. Added an **ACCEPT** rule for the Load Balancer host:
   ```bash
   sudo iptables -I INPUT 1 -p tcp -s <lbr-ip> --dport 3003 -j ACCEPT
   ```

4. Added a **REJECT** rule for everyone else:
   ```bash
   sudo iptables -A INPUT -p tcp --dport 3003 -j REJECT
   ```

5. Persisted the rules across reboots:
   ```bash
   sudo iptables-save > /etc/sysconfig/iptables
   ```

**Then replicated the same steps on App Servers 2 and 3.**

**Key insight:** **Rule order matters.** The ACCEPT for the LBR must come **before** the REJECT for everyone else — otherwise the REJECT catches it first and traffic never reaches the ACCEPT.

---

## ☁️ 100 Days Cloud (AWS)

### Task

Create an AMI from an existing EC2 instance named `devops-ec2`.

**Requirements:**
- AMI name: `devops-ec2-ami`
- Verify the AMI is in **available** state

### What I did

1. Retrieved the instance ID:
   ```bash
   aws ec2 describe-instances \
     --filter "Name=tag:Name,Values=devops-ec2" \
     --query "Reservations[].Instances[].InstanceId"
   ```

2. Created the AMI:
   ```bash
   aws ec2 create-image \
     --instance-id <instance-id> \
     --name devops-ec2-ami \
     --no-reboot
   ```

3. (Optional) Waited for it to be available:
   ```bash
   aws ec2 wait image-available --image-ids <ami-id>
   ```

**Result:** ✅ AMI created successfully.

---

## 📚 Personal Task

**Linux L1 Certification Test — Attempted.**

Assessment complete.

---

## 🎯 Day 13 Takeaways

| Lesson | Detail |
|---|---|
| **Order matters in iptables** | ACCEPT for specific sources must precede blanket REJECT |
| **Persist rules** | `iptables-save > /etc/sysconfig/iptables` survives reboot |
| **Two-sided rule design** | Allow specific → deny everyone else (not the reverse) |
| **AMI creation is fast** | `create-image` returns immediately; use `wait image-available` to block until ready |
| **Reproducibility** | Same fix across all three app servers — no drift |
