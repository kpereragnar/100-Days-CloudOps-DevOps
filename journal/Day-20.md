```markdown
# CloudOps / DevOps Journal

## Day 20 — 2 October 2026

**Challenges:** KodeKloud 100 Days of DevOps and 100 Days of Cloud — AWS

---

## 1. 100 Days of DevOps Challenge

### Task: Configure Nginx + PHP-FPM on App Server 2

I was tasked with installing and configuring nginx and PHP-FPM to work together on App Server 2, with specific requirements:

1. Nginx on port **8095**, document root `/var/www/html`
2. PHP-FPM version **8.1**, using the unix socket `/var/run/php-fpm/default.sock`
3. Both services working together
4. Testable from the jump host via `curl http://stapp02:8095/index.php`

The task also warned that `index.php` and `info.php` were already placed in `/var/www/html` and must not be modified.

### What I Did

**Step 1 — Installed nginx and PHP 8.1:**

```bash
ssh steve@stapp02
sudo su -
yum install -y nginx

dnf module reset php -y
dnf module enable php:8.1 -y
dnf install -y php php-fpm php-mysqlnd php-cli php-xml php-gd php-mbstring
```

**Step 2 — Created the socket parent directory:**

```bash
mkdir -p /var/run/php-fpm
chown -R nginx:nginx /var/run/php-fpm
```

**Step 3 — Configured PHP-FPM:**

Edited `/etc/php-fpm.d/www.conf`:

```ini
user = nginx
group = nginx
listen = /var/run/php-fpm/default.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
```

**Step 4 — Configured nginx:**

Edited `/etc/nginx/nginx.conf` — set the server block to listen on 8095, with the correct root and PHP handling via `fastcgi_pass unix:/var/run/php-fpm/default.sock;`.

**Step 5 — Validated and started:**

```bash
nginx -t
systemctl enable --now nginx
systemctl enable --now php-fpm
```

**Step 6 — Opened the firewall:**

```bash
firewall-cmd --permanent --add-port=8095/tcp
firewall-cmd --reload
```

### Issues I Faced and How I Fixed Them

**Issue 1 — ACL warning on PHP-FPM startup**

When I ran `php-fpm` manually to check if it was working, I got:

```
WARNING: [pool www] ACL set, listen.owner = 'nginx' is ignored
WARNING: [pool www] ACL set, listen.group = 'nginx' is ignored
```

**What it meant:** The `/var/run/php-fpm` directory had a POSIX ACL applied. When ACLs are present, PHP-FPM ignores its own `listen.owner`/`listen.group` settings because the ACL wins.

**Fix:** Instead of fighting the ACL, I set it to allow nginx access directly:

```bash
setfacl -m u:nginx:rwx /var/run/php-fpm
setfacl -d -m u:nginx:rwx /var/run/php-fpm
```

Also realized I shouldn't have been running `php-fpm` manually in the first place — used `systemctl start php-fpm` after that.

**Issue 2 — 404 Not Found from curl**

After everything was configured, `curl http://stapp02:8095/index.php` returned:

```
HTTP/1.1 404 Not Found
```

This was the tricky one. Nginx was responding (not a 502), so PHP-FPM and nginx *were* talking. But nginx couldn't find the PHP file.

**What I checked first:**
- `ls /var/www/html/` — files were there ✅
- `nginx -T | grep fastcgi_pass` — the config looked right ✅
- `tail /var/log/nginx/error.log` — showed nginx trying to serve the file but failing

**The actual root cause:** There was **another `php-fpm.conf` file in `/etc/nginx/conf.d/`** that was also defining PHP handling — and it pointed at a different socket path. Since nginx includes `conf.d/*.conf` in addition to whatever is in `nginx.conf`, that drop-in was **silently overriding my config**.

**The fix:** Removed the conflicting drop-in:

```bash
mv /etc/nginx/conf.d/php-fpm.conf /root/
nginx -t
systemctl restart nginx
```

After that, `curl http://stapp02:8095/index.php` returned the expected content.

**The verification command that made everything obvious:**

```bash
nginx -T
```

`nginx -T` (capital T) dumps the **full merged config** — every `include` expanded, in the order nginx actually reads them. That's how I spotted the duplicate `fastcgi_pass` and the wrong socket path.

### Lesson Learned

**Nginx doesn't just read `nginx.conf`.** It also reads:
- `/etc/nginx/conf.d/*.conf`
- `/etc/nginx/default.d/*.conf`

Any of these can override what's in `nginx.conf` — and they win, because they're included **after** the main file's content in most default setups.

The debugging habit that saved me: **always run `nginx -T` when a config isn't behaving as written.** Grep the output for the directive that's failing:

```bash
nginx -T 2>/dev/null | grep -n "fastcgi_pass"
nginx -T 2>/dev/null | grep -n "listen.*8095"
nginx -T 2>/dev/null | grep -n "^ *root "
```

If any directive appears **twice**, you have a conflict. If it appears once but doesn't match what you wrote, something else is defining it.

Also: `404 Not Found` from nginx after a PHP setup is almost never a PHP problem. It's nginx failing to find the file at the path it's looking — wrong `root`, missing `index.php`, or a conflicting drop-in that reset the `root`.

---

## 2. 100 Days of Cloud Challenge — AWS

### Task: Create an IAM Role for EC2 Use Case

I was tasked with:

1. Creating an IAM role named `iamrole_rose`
2. Entity type = AWS Service, Use case = EC2
3. Attaching a policy named `iampolicy_rose`

### What I Did

**Step 1 — Created the trust policy JSON.**

This was the part I wasn't sure about. A role requires a **trust policy** that says *who is allowed to assume it*. For the EC2 use case, this is:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Step 2 — Created the role:**

```bash
aws iam create-role \
  --role-name iamrole_rose \
  --assume-role-policy-document file:///tmp/trust_rose.json
```

**Step 3 — Got the policy ARN and attached it:**

```bash
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='iampolicy_rose'].Arn" --output text)

aws iam attach-role-policy \
  --role-name iamrole_rose \
  --policy-arn "$POLICY_ARN"
```

**Step 4 — Verified:**

```bash
aws iam get-role --role-name iamrole_rose \
  --query "Role.AssumeRolePolicyDocument" --output json

aws iam list-attached-role-policies --role-name iamrole_rose
```

### Issues I Faced and How I Fixed Them

**Issue — Didn't know the trust policy JSON structure**

The CLI command `--assume-role-policy-document` expects a JSON file, but I didn't know what should go inside it. Coming from the console UI (where you just pick "AWS Service → EC2" from dropdowns), the CLI version felt opaque.

**The fix:** I looked up the trust policy structure and realized it maps 1:1 to the console selections:

| Console field | JSON equivalent |
|---|---|
| Trusted entity → AWS Service | `"Principal": {"Service": "..."}` |
| Use case → EC2 | `"ec2.amazonaws.com"` |
| (implicit) | `"Action": "sts:AssumeRole"` |

The "Use case" is just a friendly label for the service principal. For EC2, it's `ec2.amazonaws.com`. For Lambda, `lambda.amazonaws.com`. For ECS Tasks, `ecs-tasks.amazonaws.com`.

### What I Learned

**Trust policies vs identity policies** — I'd only ever seen identity policies before (the ones that grant permissions *to* a user/role). A trust policy is the opposite direction: it defines **who can assume the role**. Both use the same JSON skeleton but with different fields:

| Field | Identity policy | Trust policy |
|---|---|---|
| Grants what | Actions on resources | Who can assume |
| Uses `Principal` | ❌ No | ✅ Yes |
| Uses `Action: sts:AssumeRole` | ❌ Usually not | ✅ Always |

**ARNs everywhere.** Same lesson as Day 19 — every IAM attach/detach command takes an ARN, not a name or ID. Once you internalize that pattern, IAM CLI stops feeling mysterious.

**Console ↔ CLI mapping matters.** Console is friendlier for one-off exploration. CLI forces you to understand the underlying structure. Both are useful; the CLI version teaches you what's actually happening.

### Still to learn

- Inline policies vs managed policies in practice
- When to use roles vs users
- Instance profiles (the wrapper around roles for EC2)
- Policy conditions (`StringEquals`, `IpAddress`, `ArnLike`)

---

## 3. Personal Task

**Created a Dockerfile for my security tool — `hybrid_scanner`.**

Applied the Dockerfile patterns I've been practicing:
- Multi-stage build (builder → runtime)
- Non-root user
- Explicit `EXPOSE`
- Proper `ENTRYPOINT` for a scanner CLI

This was the first Dockerfile I've written for a tool I built myself — different from following tutorials because I had to think about which layers to include, what to leave out, and how the container should behave when someone runs it.

---

## Key Takeaways

- 🔍 **`nginx -T` shows the real merged config.** When a directive isn't behaving, this is the tool to reach for.
- 📁 **Check `/etc/nginx/conf.d/` before editing `nginx.conf`.** Drop-ins silently override.
- 🌐 **A 404 from nginx with PHP ≠ a PHP problem.** It's usually a `root` mismatch or a conflicting drop-in.
- 🔐 **Trust policies define *who can assume*, identity policies define *what they can do*.** Both use the same `Version: "2012-10-17"` skeleton.
- 🔑 **IAM commands take ARNs, not names.** Same pattern as Day 19 — the CLI wants the canonical identifier.
- 📝 **Console ↔ CLI mapping is a learning tool.** When you don't know why the CLI expects a certain format, imagine the console UI — the format usually mirrors it.
- 🐳 **Writing your own Dockerfile for your own tool is different from following a tutorial.** You have to think about what actually belongs in the image.

---

## Day Status

| Area                       | Status       |
| -------------------------- | ------------ |
| 100 Days of DevOps         | 🟢 Completed |
| 100 Days of Cloud — AWS    | 🟢 Completed |
| Personal Docker Practice   | 🟢 Completed |

### Overall: 🟢 Day 20/100 — Completed

> **Major realization:** Both failures today were configuration *precedence* issues, not syntax issues. The nginx drop-in overrode my main config; the IAM trust policy format wasn't obvious from the CLI alone. In both cases the fix was to understand **which layer actually wins** — and to verify with the right diagnostic tool (`nginx -T`, `get-role --query AssumeRolePolicyDocument`). The tooling is fine; you just have to know which layer it's listening to.
```

