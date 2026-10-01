```markdown
# CloudOps / DevOps Journal

## Day 19 — 1 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Deploy Two Websites on Apache with a Custom Port

I was tasked with installing and configuring a web application on App Server 1, changing the port to **6400**, setting the server name to the app server's hostname, and serving two website directories (`/beta` and `/demo`) that were located on the jump host.

### What I Did

**Step 1 — Installed Apache:**

```bash
ssh tony@stapp01
sudo su -
yum install -y httpd
```

**Step 2 — Edited the main configuration file:**

```bash
vi /etc/httpd/conf/httpd.conf
```

Changes made:
- Changed `Listen 80` → `Listen 6400`
- Set `ServerName` to `stapp01`
- Ensured `DocumentRoot` was `/var/www/html`

**Step 3 — Copied the website directories from the jump host:**

From the jump host:

```bash
scp -r /beta tony@stapp01:/tmp/
scp -r /demo tony@stapp01:/tmp/
```

On the app server:

```bash
cp -r /tmp/beta /var/www/html/
cp -r /tmp/demo /var/www/html/
```

**Step 4 — Set proper permissions for security and efficiency:**

```bash
chown -R apache:apache /var/www/html/beta /var/www/html/demo
chmod -R 755 /var/www/html/beta /var/www/html/demo
```

**Step 5 — Validated the configuration:**

```bash
httpd -t
```

Result:

```
Syntax OK
```

**Step 6 — Restarted the service:**

```bash
systemctl restart httpd
systemctl enable httpd
systemctl status httpd
```

**Step 7 — Tested from the jump host:**

```bash
curl http://stapp01:6400/demo/
curl http://stapp01:6400/beta/
```

Both websites were reachable.

### Lesson Learned

The key takeaway was the importance of **validating before restarting**. Running `httpd -t` before `systemctl restart` catches config errors early — if the syntax is wrong, the restart would have failed and taken the whole service down.

Also reinforced: setting proper ownership (`apache:apache`) and permissions (`755`) on web content isn't just good practice — Apache runs as the `apache` user, and it needs read access to serve files. Wrong ownership = 403 Forbidden even if the config is perfect.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Attach a User Policy to an IAM User

I was tasked with attaching a policy to an IAM user.

This was a first for me — I'm still getting comfortable with the whole IAM policy model.

### What I Did

I looked up the command in my notes and used:

```bash
aws iam attach-user-policy \
  --user-name <username> \
  --policy-arn <policy-arn>
```

### What I Learned

**IAM policies are identified by their ARN, not their ID.**

- The **policy ID** (e.g., `ANPAIOSFODNN7EXAMPLE`) is an internal identifier — not used in API calls.
- The **policy ARN** (e.g., `arn:aws:iam::123456789012:policy/MyPolicy`) is what you pass to attach/detach commands.

You can get the ARN with:

```bash
aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='<name>'].Arn" \
  --output text
```

Or with the ID-lookup pattern:

```bash
aws iam get-policy --policy-arn <arn> --query "Policy.Arn" --output text
```

### Where the command lives in my cheat sheet

Section **5.5 Attachments**:

```bash
aws iam attach-user-policy --user-name <name> --policy-arn <arn>
aws iam list-attached-user-policies --user-name <name>
aws iam detach-user-policy --user-name <name> --policy-arn <arn>
```

### Still to learn

- The difference between **managed policies** vs **inline policies**
- How to build a policy document (the JSON structure)
- Trust policies (used with roles)
- The `Version: "2012-10-17"` requirement

These are things I'll pick up as I work through more IAM tasks.

---

## 3. Personal Task

**Docker practice.** Plan to watch some videos and continue hands-on practice on Docker concepts.

---

## Key Takeaways

- 🛡️ **Always validate config before restart.** `httpd -t` catches syntax errors before they cause downtime.
- 📁 **Ownership matters.** Web content must be owned by the user Apache runs as (`apache:apache`) or it returns 403.
- 🚚 **File transfer workflow:** `scp` to `/tmp` first, then move into place — cleaner than scp'ing directly into production paths.
- 🔑 **IAM policies use ARNs.** The policy ID is internal; every API call takes the ARN.
- 🧩 **Validate, then restart, then test.** Applies to Apache, nginx, and any service with a `-t` syntax check.
- 🔍 **Look up before guessing.** Checking my notes for the correct `attach-user-policy` syntax saved a failed attempt.

---

## Day Status

| Area                       | Status       |
| -------------------------- | ------------ |
| 100 Days of DevOps         | 🟢 Completed |
| 100 Days of Cloud — AWS    | 🟢 Completed |
| Personal Docker Practice   | 🟢 Started   |

### Overall: 🟢 Day 19/100 — Completed

> **Major realization:** A web server that passes `httpd -t` isn't necessarily serving content — ownership and permissions on the DocumentRoot are just as important as the config file. And in IAM, the identifier you need is always the ARN, not the internal ID. Both were small reminders that the "obvious" step isn't always the whole story.
```

---

