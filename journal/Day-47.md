# CloudOps / DevOps Journal

## Day 47 — 29 October 2026

**Challenges:** 100 Days of DevOps, 100 Days of Cloud, and Terraform L2

> **Context:** Long day at AFIT. Terraform L2 not attempted — tired and sleepy after work. The 100 Days tasks got done; the extra-track task did not. **Not a discipline failure — a real-world constraint the plan absorbs.** Terraform finish date holds if the 2/day window extends by two days.

---

## 1. 100 Days of DevOps — Docker Compose Stack on App Server 3

**Task:** Two-service stack at `/opt/data/docker-compose.yml`. Web (`php_web`, `php:apache`, port 8085→80, host `/var/www/html`), DB (`mysql_web`, `mariadb:latest`, port 3306→3306, host `/var/lib/mysql`, `MYSQL_DATABASE=database_web`, custom user + complex password).

**The compose file:**

```yaml
version: "3.8"

services:
  web:
    image: php:apache
    container_name: php_web
    ports:
      - "8085:80"
    volumes:
      - /var/www/html:/var/www/html
    depends_on:
      - db

  db:
    image: mariadb:latest
    container_name: mysql_web
    ports:
      - "3306:3306"
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    environment:
      MYSQL_DATABASE: database_web
      MYSQL_USER: dbuser
      MYSQL_PASSWORD: 'S3cur3P@ss!2026'
      MYSQL_ROOT_PASSWORD: 'R00tP@ss!2026'
```

**Commands:**

```bash
ssh tony@stapp03
sudo mkdir -p /opt/data
# write compose file
cd /opt/data && docker compose up -d

# Verify
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
docker port php_web      # → 80/tcp -> 0.0.0.0:8085
docker port mysql_web    # → 3306/tcp -> 0.0.0.0:3306
docker exec mysql_web env | grep MYSQL_
curl -I http://localhost:8085/
```

### Key Learning

**MariaDB needs a root password even when you're not using root.** Without one of `MYSQL_ROOT_PASSWORD`, `MYSQL_ALLOW_EMPTY_PASSWORD`, or `MYSQL_RANDOM_ROOT_PASSWORD`, the container refuses to start. **The task asks for a custom user — that's `MYSQL_USER`. Both variables are required:** the root password lets the DB initialise; the custom user is what the app connects as.

**`php:apache` is the tag, not `php:latest-apache`.** The official PHP image uses `apache` as a suffix. Adding `latest-` breaks the tag lookup.

**`depends_on` waits for start, not readiness.** Same lesson as Day 39's Compose healthcheck task. Nothing in `php_web` connects to `mysql_web` at boot here, so it's cosmetic — but a real app would need a `healthcheck` block on `db` with `condition: service_healthy` on `web`'s `depends_on`.

**`curl` returning 403 is still success.** `php:apache` serves `/var/www/html`; empty directory gives 403 Forbidden. The grader checks reachability, not content.

---

## 2. 100 Days of Cloud — Lambda + S3 + DynamoDB Event-Driven Copy

**Task:** Public bucket `datacenter-public-801766052` → Lambda `datacenter-copyfunction` copies uploads to private bucket `datacenter-private-801766052` → log row written to DynamoDB `datacenter-S3CopyLogs` (partition key `LogID`). Role `lambda_execution_role`, 128 MB memory, 10s timeout.

### What went wrong — five failures, one root cause

**Failure 1 — heredoc swallowed a command**

```bash
cat > /tmp/lambda-policy.json <<EOF
{ ...policy JSON... }
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

The `EOF` was missing. The `--policy-arn` line became part of the JSON file, **and the `create-role` step after it never ran**. The role didn't exist.

**Failure 2 — cascade of `NoSuchEntity`**

Every downstream command failed:
```
NoSuchEntity: lambda_execution_role cannot be found
ValidationException: Value '' at 'role' failed to satisfy constraint
```

The empty `$ROLE_ARN` produced a completely different-looking error. **The first error was the real one. Everything after was echo.**

**Failure 3 — `create-policy` returned `EntityAlreadyExists`**

On retry, the policy existed from the earlier attempt, so `create-policy` failed with `EntityAlreadyExists`, leaving `$POLICY_ARN` empty. The subsequent `attach-role-policy` failed with `Invalid length for parameter PolicyArn, value: 0, valid min length: 20`.

**The fix:** `list-policies --scope Local` to fetch the existing ARN, rather than recreating.

**Failure 4 — `zip -f` doesn't create archives**

```bash
zip -f function.zip lambda-function.py
# zip warning: function.zip not found or empty
```

`-f` means "freshen" — updates existing entries, doesn't create. Then `create-function` failed with `Unable to load paramfile fileb://function.zip`.

**The fix:** plain `zip` (no `-f`), and use absolute paths (`fileb:///root/function.zip`) to remove the working-directory ambiguity.

**Failure 5 — THE REAL ONE: hyphen vs underscore**

```bash
Runtime.ImportModuleError: Unable to import module 'lambda_function': No module named 'lambda_function'
```

The handler is `lambda_function.lambda_handler` (underscore). The file inside the zip was `lambda-function.py` (hyphen). **Python cannot import hyphenated filenames** — `import lambda_function` looks for `lambda_function.py` exactly. The handler never ran, so nothing was written to DynamoDB.

Every invocation since 19:55 failed the same way. **Six uploads, six `ImportModuleError`, six empty DynamoDB scans.** The trigger was fine, the IAM was fine, the file was uploaded — **the code never loaded.**

### The fix

```bash
# 1. Rebuild policy JSON cleanly (with proper EOF)
cat > /tmp/lambda-policy.json <<EOF
{ ...policy... }
EOF
python3 -m json.tool /tmp/lambda-policy.json > /dev/null && echo "VALID"

# 2. Create the role (or fetch existing)
aws iam get-role --role-name lambda_execution_role 2>/dev/null || {
  aws iam create-role --role-name lambda_execution_role \
    --assume-role-policy-document file:///tmp/trust-policy.json
}
aws iam list-attached-role-policies --role-name lambda_execution_role \
  --query "AttachedPolicies[].PolicyName" --output text

# 3. Fetch existing policy ARN if create-policy fails
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='lambda-s3-copy-dynamodb-policy'].Arn" \
  --output text)

# 4. Rename to underscore INSIDE the zip
sudo cp /root/lambda-function.py /root/lambda_function.py
sudo rm -f /root/function.zip
sudo bash -c 'cd /root && zip function.zip lambda_function.py'
sudo unzip -l /root/function.zip    # → lambda_function.py (UNDERSCORE)

aws lambda update-function-code \
  --function-name datacenter-copyfunction \
  --zip-file fileb:///root/function.zip

aws lambda wait function-updated --function-name datacenter-copyfunction

# 5. Re-trigger
aws s3 cp /root/sample.zip s3://datacenter-public-801766052/sample.zip
sleep 20
```

### Key Learning

**The diagnostic ladder found the real failure.** Four checks in order:

1. **Trigger configured?** ✅ `get-bucket-notification-configuration` showed the Lambda ARN
2. **File uploaded?** ✅ `s3 ls` showed `sample.zip`
3. **Lambda invoked?** ✅ `describe-log-streams` showed a stream
4. **Code loaded?** ❌ `filter-log-events` showed `ImportModuleError` ← **the actual failure**
5. **DynamoDB wrote?** ⬜ Never reached — step 4 blocked everything

**Every step above 4 was passing. Every step below 4 was failing.** The error at step 4 named the exact fix.

**Five failures, one root cause, but each surfaced as a different error.** The heredoc ate the create-role step → the role was missing → the Lambda create failed on an empty ARN → the zip didn't exist → the file was named wrong → the module didn't load → the DynamoDB was empty. **Six different error messages, six different commands to fix, one chain of causality that started with one missing `EOF`.**

**The one-block diagnostic that isolates it:**

```bash
aws logs filter-log-events \
  --log-group-name "/aws/lambda/datacenter-copyfunction" \
  --start-time $(($(date +%s) * 1000 - 300000)) \
  --query "events[].message" --output text | grep -E "INFO|ERROR"
```

**The Lambda log is always the final answer.** The AWS CLI commands told me what I did; the Lambda log told me what the code actually experienced. **When the write succeeded but nothing happened, the log is the only witness.**

**`aws logs tail` doesn't exist in this CLI version** — use `filter-log-events` with a time window. Same lesson as `aws logs tail --follow` being v2-only (Docker sheet aside).

---

## 3. Terraform L2 — Not Attempted

**Status:** No Terraform task completed on Day 47.

**Reason:** Long day at AFIT. Energy gone by the time I sat down. Not a discipline lapse — a real-world constraint.

**The plan's adjustment:**

Original schedule: 2/day through Oct 31 (4 days = 8 tasks), then 1/day Nov 1–12 (12 tasks), **finish Nov 12**, 1,600 coins.

Day 46 done: 2 tasks (VPC+Subnet depends_on, Private VPC+EC2). Day 47 done: 0. **18 tasks remain over 14 days (Oct 30 – Nov 12).**

The fix: **extend the 2/day window by two days** — Oct 30, 31, Nov 1, Nov 2 (4 days × 2 = 8 tasks), then 1/day Nov 3–12 (10 tasks). Total 18 ✓. Coins: 4 × 400 = 1,600 ✓. **Finish Nov 12 unchanged. Coin cost unchanged.**

**K8 L1 is unaffected** — it starts Nov 13 because Terraform finishes Nov 12, not because of how many 2/day days Terraform had.

### Key Learning

**The plan absorbed a day off without a dependency breaking.** Same as Day 42's power outage — the schedule has slack built into the "2/day through X" windows, and the 1/day tail is the pressure valve. **Extend the 2/day window, don't extend the finish date.** The only thing that actually moves the finish line is a dependency break (K8 start needs Terraform done), and that didn't happen.

**The honest journal entry matters more than the perfect one.** A journal that only records the days that went to plan is not a record of the work — it's a record of the good days. **The days that didn't go to plan are the ones that teach what "resilient plan" means.** Day 42 had the power outage. Day 47 had the AFIT day. Both are entries. Both are the plan working as designed.

---

## Timeline

| Track | Date | Status |
|---|---|---|
| Terraform L1 | 27 Oct | ✅ 75% pass |
| **Terraform L2** | 28 Oct → **Nov 12** (adjusted) | 2/20 tasks done |
| **K8 L1** | Nov 13 → **Nov 19** | Unaffected |
| K8 L2 | Late Nov / Dec | Needs coins |
| 100 Days Day 100 | 22 Dec | On track |
| Projects start | 22 Nov | On track |

**Terraform finish holds Nov 12.** 2/day through Nov 2 instead of Oct 31. Same finish, same coins.

---

## Key Takeaways

- 🐳 **MariaDB needs a root password** even when using a custom user. `MYSQL_ROOT_PASSWORD` + `MYSQL_USER` are both required.
- 🐳 **`depends_on` waits for start, not readiness.** Use `healthcheck` + `condition: service_healthy` when the app connects at boot.
- ☁️ **Heredoc without closing `EOF` swallows the next command.** The failure surfaces later as a completely different error. **Validate JSON files with `python3 -m json.tool` immediately after creating them.**
- ☁️ **`EntityAlreadyExists` on `create-policy` leaves the ARN empty.** Fetch the existing ARN with `list-policies --scope Local` instead of re-creating.
- ☁️ **`zip -f` doesn't create archives.** `-f` means freshen. Use plain `zip` and absolute paths.
- ☁️ **`lambda-function.py` (hyphen) ≠ `lambda_function.py` (underscore).** Python cannot import hyphenated filenames. `Runtime.ImportModuleError: Unable to import module 'lambda_function'` names the exact fix.
- ☁️ **The diagnostic ladder isolates the layer.** Trigger → file → Lambda invoked → code loaded → DynamoDB wrote. Whichever check is first to fail is the real problem. Everything below is echo.
- ☁️ **The Lambda log is the final answer.** The CLI commands tell you what you did; the log tells you what the code actually experienced.
- 🔧 **One missed day doesn't move the finish date if it extends the acceleration window instead.** 2/day through Nov 2, finish Nov 12, coins unchanged.
- 🔄 **The honest journal is the resilient journal.** Day 42 had the power outage. Day 47 has the AFIT day. Both are entries. Both show the plan absorbing reality.

---

## Day Status

| Area | Status |
|---|---|
| 100 Days DevOps — Compose php+maria | 🟢 Completed |
| 100 Days Cloud — Lambda + S3 + DynamoDB | 🟢 Completed (after 5 failures) |
| **Terraform L2** | ⏸️ Not attempted — tired after AFIT |

**Overall: 🟡 Day 47/100 — Partial (100 Days only)**

> **Realization:** Two things today that belong together.
>
> **The first is the Lambda debugging chain** — five failures, one root cause, spread across an hour. The heredoc ate a command, the role wasn't created, the ARN was empty, the zip didn't exist, the file was named wrong. Each one produced a different error and each one had to be fixed in order. **The diagnostic ladder is what ended the cycle** — trigger? file? invoked? code loaded? DynamoDB wrote? Each check eliminated one layer until only one remained. **The error at the layer that failed named the exact fix.** That's not luck. That's the sequence. It's the same sequence as Day 46's VPC chain, Day 40's three-layer internet check, Day 38's ECS role hunt.
>
> **The second is the Terraform miss** — and its honesty is the point. I didn't write "Terraform not done, will catch up" — I wrote "Terraform not done, plan extends acceleration by 2 days, finish date unchanged, coin cost unchanged." **That's a plan, not an apology.** The schedule has slack because the "2/day through X" windows are adjustable. The only thing that moves the finish line is a dependency break, and this wasn't one. **Day 42 taught this lesson with a power outage. Day 47 repeated it with a real day at AFIT.** The pattern holds: resilient plans absorb interruptions without changing finish dates. **The journal records both the wins and the wins that came after interruptions.**

