```markdown
# CloudOps / DevOps Journal

## Day 15 — 27 September 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Deploy Nginx with Self-Signed SSL on App Server 3

The system admins team of xFusionCorp Industries needed to prepare **App Server 3** for a new application deployment. The requirements were:

1. Install and configure Nginx on App Server 3.
2. A self-signed SSL certificate and key were present at `/tmp/nautilus.crt` and `/tmp/nautilus.key`. Move them to an appropriate location and deploy them in Nginx.
3. Create an `index.html` file with the content `Welcome!` under the Nginx document root.
4. Test from the jump host using `curl -Ik https://<app-server-name>/`.

### What I Did

**Step 1 — Installed Nginx:**

```bash
ssh banner@stapp03
sudo su -
yum install -y nginx
```

**Step 2 — Moved the certificate and key to the standard TLS locations:**

```bash
mv /tmp/nautilus.crt /etc/pki/tls/certs/nautilus.crt
mv /tmp/nautilus.key /etc/pki/tls/private/nautilus.key
chmod 600 /etc/pki/tls/private/nautilus.key
chmod 644 /etc/pki/tls/certs/nautilus.crt
```

**Step 3 — Created the SSL server block.**

I initially tried editing `/etc/nginx/nginx.conf` directly to add the SSL configuration. This caused Nginx to fail with:

```
nginx: [emerg] "listen" directive is not allowed here
```

The `listen 443 ssl;` directives ended up **outside a proper `server {}` block** — either appended after the closing brace of the previous `server`, or after the closing brace of `http {}`. Nginx rejected the config because `listen` is only valid inside `server {}`, and `server {}` is only valid inside `http {}`.

### Troubleshooting the Nginx Config Issue

I ran a quick diagnostic to see where each `listen` directive actually lived:

```bash
grep -rn "listen" /etc/nginx/
```

The output showed the 443 listens in `/etc/nginx/nginx.conf` at lines 59–60, but they were not properly wrapped in their own `server {}` block.

### The Fix

Rather than fighting the main `nginx.conf`, I restored it from the package default and moved the SSL configuration into a **drop-in file** under `/etc/nginx/conf.d/` — where files are auto-included inside `http {}`.

**Restored the default config:**

```bash
cp /etc/nginx/nginx.conf /root/nginx.conf.bak
cp /etc/nginx/nginx.conf.default /etc/nginx/nginx.conf
```

**Created a dedicated SSL drop-in at `/etc/nginx/conf.d/ssl.conf`:**

```nginx
server {
    listen       443 ssl;
    listen       [::]:443 ssl;
    server_name  stapp03;

    ssl_certificate     /etc/pki/tls/certs/nautilus.crt;
    ssl_certificate_key /etc/pki/tls/private/nautilus.key;

    root   /usr/share/nginx/html;
    index  index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

**Validated the config:**

```bash
nginx -t
```

Result:

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Step 4 — Created the index file:**

```bash
echo "Welcome!" > /usr/share/nginx/html/index.html
```

**Step 5 — Started and enabled Nginx:**

```bash
systemctl enable --now nginx
systemctl restart nginx
systemctl status nginx
```

**Step 6 — Opened the firewall for HTTPS:**

```bash
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

**Step 7 — Tested from the jump host:**

```bash
curl -Ik https://stapp03/
```

Result:

```
HTTP/1.1 200 OK
Server: nginx/...
```

The `-k` flag was required because the certificate is self-signed — curl rejects self-signed certificates by default with `SSL certificate problem: self-signed certificate`.

### Lesson Learned

The biggest takeaway was understanding **Nginx's configuration hierarchy**:

```
http {
    server {
        listen ...;
    }
}
```

- `listen` is **only valid inside `server {}`**
- `server {}` is **only valid inside `http {}`**
- Files in `/etc/nginx/conf.d/*.conf` are auto-included inside `http {}`, so a bare `server {}` block in one of those files is correct
- Pasting `server {}` blocks directly into `/etc/nginx/nginx.conf` requires careful attention to brace placement

The error message was precise: **`"listen" directive is not allowed here`** tells you the `listen` is outside a `server {}` block. Combined with `grep -rn "listen" /etc/nginx/`, you can find the offending line in seconds.

**A secondary lesson:** when a config gets tangled, restoring from `nginx.conf.default` and using drop-ins under `conf.d/` is almost always faster than trying to fix the main file by hand.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create a Snapshot of an Existing Volume

The Nautilus DevOps team had volumes across different AWS regions and wanted to set up automated backups. My task was to create a snapshot of an existing volume.

**Requirements:**

1. Volume name: `nautilus-vol` in `us-east-1`
2. Snapshot name: `nautilus-vol-ss`
3. Snapshot description: `nautilus Snapshot`
4. Snapshot status must be `completed` before submitting

### What I Did

**Step 1 — Retrieved the volume ID:**

```bash
aws ec2 describe-volumes \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=nautilus-vol" \
  --query "Volumes[0].VolumeId" \
  --output text
```

**Step 2 — Created the snapshot.**

My first attempt used the wrong approach — I tried to use `--tag-specifications` to set the description as a tag and had a duplicate `--tag-specifications` flag:

```bash
aws ec2 create-snapshot --volume-id vol-0bc0d1da5869976bc \
  --tag-specifications \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=datacenter-vol-ss},{Key=Description,Value="datacenter Sanpshot"}]'
```

This failed. Two problems:

1. **Duplicate `--tag-specifications` flag** — the second one overrode the first, which had no value. AWS CLI rejected the malformed invocation.
2. **Description was set as a tag** — the task required an actual snapshot *description*, not a tag called `Description`.

### The Fix

I checked `aws ec2 create-snapshot help` and discovered the correct approach: **`--description` is a first-class flag** for `create-snapshot`. The task's "description" requirement is about the snapshot's `Description` field, not a tag.

**Correct command:**

```bash
aws ec2 create-snapshot \
  --region us-east-1 \
  --volume-id vol-0bc0d1da5869976bc \
  --description "nautilus Snapshot" \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=nautilus-vol-ss}]'
```

**Step 3 — Waited for the snapshot to complete:**

```bash
aws ec2 wait snapshot-completed \
  --region us-east-1 \
  --snapshot-ids <snapshot-id>
```

**Step 4 — Verified:**

```bash
aws ec2 describe-snapshots \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=nautilus-vol-ss" \
  --query "Snapshots[0].{Name:Tags[?Key=='Name']|[0].Value,State:State,Description:Description}" \
  --output table
```

Expected:

```
State: completed
Description: nautilus Snapshot
Name: nautilus-vol-ss
```

### Lesson Learned

This task exposed **two mistakes I should avoid in the future**:

**1. Don't confuse tags with first-class fields.**
The description of a snapshot is not a tag — it's a dedicated field. AWS CLI has `--description` for this. Using `--tag-specifications` to approximate a description leads to incorrect config.

**2. Read the help output.**
`aws ec2 create-snapshot help` lists every flag the command accepts. `--description` is right there. If I'd checked before running, I would have avoided the failure entirely.

Also learned: **`aws ec2 wait snapshot-completed`** is the clean way to block until the snapshot is in `completed` state, rather than polling `describe-snapshots` in a loop.

---

## 3. Personal Task

### KodeKloud Engineer Docker L1

Continued working through **Docker L1** tasks.

Practiced:
- Running an Ubuntu container and creating files inside it with `docker exec`
- Listing images with `docker images`, including filters and format options
- Understanding the difference between `nginx` and `nginx:alpine` images
- Running a named container (`docker run -d --name nginx_2 nginx:alpine`)

---

## Key Takeaways

- **Nginx config hierarchy matters.** `listen` belongs inside `server {}`, and `server {}` belongs inside `http {}`. Errors like `"listen" directive is not allowed here` mean the directive is misplaced.
- **Use drop-in files.** `/etc/nginx/conf.d/*.conf` is the clean place for site configs. Don't edit `nginx.conf` unless you have to.
- **`nginx.conf.default` is a safety net.** Restore from it when config gets tangled.
- **`nginx -t` before restart.** Always validate. It catches errors before they cause downtime.
- **`grep -rn "listen" /etc/nginx/`** is a fast way to see where every listen directive lives.
- **`--description` is its own flag**, not a tag. Check `aws ec2 <command> help` for the correct parameters.
- **`aws ec2 wait snapshot-completed`** blocks until the snapshot is ready — cleaner than polling.
- **Read the help output** before running a command you're not 100% sure about. Two minutes of reading saves a failed attempt.

### Day Status

| Area                     | Status               |
| ------------------------ | -------------------- |
| 100 Days of DevOps       | 🟢 Completed         |
| 100 Days of Cloud — AWS  | 🟢 Completed         |
| Personal Docker Practice | 🟢 In Progress       |

> **Major realization:** Both failures today came down to reading the requirements carefully. The Nginx error was a config structure issue I could have prevented by understanding the file hierarchy. The snapshot failure was a wrong assumption about how the description should be set. **Read the docs. Read the error. Read the requirements.** The task tells you what it wants — it's my job to match it exactly.

**Overall: 🟢 Day 15/100 — Completed**
```
