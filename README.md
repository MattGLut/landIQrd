# LandIQrd

A property management app for small (1-15 unit) landlords. Tenants, landlords,
contractors, and admins collaborate around leases, work requests, and messaging.

## Stack

- Ruby on Rails 8 (Hotwire: Turbo + Stimulus), server-rendered.
- PostgreSQL, Devise (auth), Pundit (authorization).
- ActiveStorage (local disk in dev/test, S3 in staging/production).
- Solid Queue (background jobs), Action Cable (real-time messaging).
- Stimulus controllers: sidebar, work order status, notification preferences.
- RSpec, FactoryBot, Capybara, SimpleCov.
- Deploy via Kamal (Docker) to a single EC2 host + RDS + S3; CI via GitHub Actions.

## Local setup

```bash
bundle install            # gems install into vendor/bundle (see .bundle/config)
bin/rails db:prepare      # create + migrate
bin/dev                   # boots Puma + Tailwind watcher
```

Always run tooling through Bundler (`bundle exec ...`) because gems are vendored.

Optional demo data (development only):

```bash
bin/rails db:seed
```

Default password for every seeded account is `password123`. Seeded emails:

- `admin@propman.test` (admin)
- `landlord@propman.test` (landlord)
- `tenant@propman.test` (tenant)
- `contractor@propman.test` (contractor)

Seeds are skipped in test and production.

### Roles

`User#role` is an enum: `tenant`, `landlord`, `contractor`, `admin`. Self
sign-up is limited to tenant/landlord/contractor; admins are created via the
admin console or the console.

## Features

### Properties and units

Landlords create and manage properties (name, address) and units (label,
bedrooms, bathrooms, square feet). Visibility is scoped by role via Pundit
policies.

### Leases

Leases move through draft, active, ended, and terminated statuses. Only one
active lease is allowed per unit. Landlords upload lease documents via
ActiveStorage. Active leases past their end date are ended automatically by
`Leases::ExpireDueJob` (daily at 6am; see `config/recurring.yml`).

### Lease invitations

Landlords invite prospective tenants by email. The invitee receives a token
link (`/invites/:token`), signs up, and accepts into a draft lease on the
target unit.

### Work orders

Tenants and landlords submit maintenance requests with category, priority, and
photos. Statuses follow an AASM state machine: open, pending_tenant,
pending_management, on_hold, completed, and cancelled. Landlords manage
transitions; tenants can close and reopen their requests. Closure requires a
reason. Every change is recorded in a work order event log.

Landlords assign contractors with an optional scheduled date. Landlords and
contractors can view upcoming assignments at `/work_orders/schedule`. Each
assigned work order gets a conversation thread.

### Messaging

Work-order threads and direct messages between two users. Messages support
file attachments. New messages broadcast in real time via Turbo Streams (Action
Cable). Unread counts are tracked per participant.

### Notifications

Six email notification types, each opt-out per user and filtered by role (see
`User::EMAIL_NOTIFICATION_TYPES`). Users manage preferences at
`/account/notifications` with auto-save toggles.

### Account

Profile settings (preferred name, avatar), notification preferences, and
Devise email and security settings under `/account`.

### Admin

The `/admin` namespace provides user CRUD plus read-only views of properties,
work orders, and conversations.

## Running the test suite

```bash
bundle exec rspec
bundle exec rubocop
bin/brakeman
```

GitHub Actions runs Brakeman, Bundler Audit, importmap audit, RuboCop, and the
full RSpec suite on every pull request and push to `main`.

---

## Production deployment

LandIQrd deploys with **Kamal** to a single **EC2** instance. The app container
talks to **RDS PostgreSQL**, **S3** (file uploads), and **SendGrid** (email).
**Cloudflare** sits in front of the server for DNS and TLS termination at the
edge.

```
Browser → Cloudflare (DNS + proxy) → EC2/Kamal proxy (Let's Encrypt) → Rails container
                                              ↓
                                    RDS PostgreSQL + S3 + SendGrid
```

### Prerequisites checklist

Before your first deploy, you should have:

- [ ] A domain managed in Cloudflare
- [ ] An EC2 instance with Docker (Kamal installs it on first deploy)
- [ ] An RDS PostgreSQL instance (two databases: primary + queue)
- [ ] An S3 bucket + IAM credentials for Active Storage
- [ ] A SendGrid account with domain authentication
- [ ] GitHub repository secrets configured for CI deploy
- [ ] `config/deploy.yml` updated with your domain, EC2 IP, and GHCR image name

---

## AWS setup

### 1. EC2 application server

1. Launch an **Ubuntu 24.04** instance (e.g. `t3.small`) in the same region as RDS
   and S3.
2. Attach or create a **key pair** — you will need the private key for Kamal SSH
   and the `SSH_PRIVATE_KEY` GitHub secret.
3. Configure the **security group**:
   - **SSH (22)** — your IP only (for Kamal deploys and debugging)
   - **HTTP (80)** and **HTTPS (443)** — `0.0.0.0/0` (Cloudflare proxies
     traffic; Kamal's proxy terminates Let's Encrypt here)
4. Note the instance **public IP** (or assign an Elastic IP so it does not
   change on reboot). You will set this in `config/deploy.yml` under `servers`.

Kamal connects over SSH and installs Docker on first deploy. No manual Docker
setup is required beyond opening port 22.

### 2. RDS PostgreSQL

The app uses multiple databases in production ([`config/database.yml`](config/database.yml)):

| Database | Purpose |
|----------|---------|
| `prop_man_production` | Application data (users, leases, work orders, etc.) |
| `prop_man_production_queue` | Solid Queue background jobs |

1. Create an **RDS PostgreSQL** instance (PostgreSQL 15+ recommended) in the
   same VPC/region as EC2.
2. Set a master username and password; note the endpoint hostname.
3. Create the databases (via psql, RDS Query Editor, or `createdb`):

```sql
CREATE DATABASE prop_man_production;
CREATE DATABASE prop_man_production_queue;
```

4. Configure the **RDS security group** to allow inbound **5432** from the EC2
   security group (not from the public internet).
5. Build connection URLs:

```
DATABASE_URL=postgres://USER:PASSWORD@your-rds-host.region.rds.amazonaws.com:5432/prop_man_production
QUEUE_DATABASE_URL=postgres://USER:PASSWORD@your-rds-host.region.rds.amazonaws.com:5432/prop_man_production_queue
```

Store both as GitHub Actions secrets. Add `QUEUE_DATABASE_URL` to
[`config/deploy.yml`](config/deploy.yml) `env.secret` and
[`.kamal/secrets`](.kamal/secrets) if it is not already listed.

The container entrypoint runs `db:prepare` on boot, which creates/migrates the
primary database and loads the Solid Queue schema.

### 3. S3 (Active Storage)

Dev/test use local disk. Production uses S3 via [`config/storage.yml`](config/storage.yml).

1. Create a **private** S3 bucket (e.g. `landiqrd-production`) in the same region
   as EC2.
2. Block all public access (Active Storage serves files through Rails, not direct
   public URLs).
3. Create an **IAM user** (or an EC2 instance role) scoped to that bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::landiqrd-production",
        "arn:aws:s3:::landiqrd-production/*"
      ]
    }
  ]
}
```

4. Create access keys for the IAM user and store them as secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
5. Set non-secret config in [`config/deploy.yml`](config/deploy.yml) `env.clear`:
   - `AWS_REGION` (e.g. `us-east-1`)
   - `S3_BUCKET` (e.g. `landiqrd-production`)

`config.active_storage.service` defaults to `:amazon` in production. Override
with `ACTIVE_STORAGE_SERVICE=local` only for debugging without S3.

### 4. Redis (real-time messaging)

Action Cable is configured to use **Redis** in production
([`config/cable.yml`](config/cable.yml)). Real-time chat (Turbo Streams) requires
a running Redis instance.

**Simplest option for a single-server deploy:** add a Redis Kamal accessory on
the same EC2 host. Uncomment and adapt the `accessories.redis` block in
[`config/deploy.yml`](config/deploy.yml), then set:

```
REDIS_URL=redis://your-ec2-private-ip:6379/1
```

Add `REDIS_URL` to `env.secret` in `deploy.yml` and `.kamal/secrets`.

Alternatively, use **ElastiCache Redis** in the same VPC and point `REDIS_URL`
at the cluster endpoint.

---

## SendGrid setup

Production mail is sent via SMTP through SendGrid
([`config/environments/production.rb`](config/environments/production.rb)).

### 1. Create API key

1. Sign up at [sendgrid.com](https://sendgrid.com).
2. Go to **Settings → API Keys → Create API Key**.
3. Choose **Restricted Access** with **Mail Send → Full Access** (or use Full
   Access for simplicity during setup).
4. Copy the key — it is shown only once. Store it as the `SENDGRID_API_KEY`
   GitHub secret.

### 2. Authenticate your domain

SendGrid must be authorized to send mail from your domain (required for reliable
delivery and to avoid spam folders).

1. Go to **Settings → Sender Authentication → Authenticate Your Domain**.
2. Choose your DNS host (**Cloudflare**).
3. Enter the domain you will send from (e.g. `landiqrd.com`).
4. SendGrid provides **CNAME records** for DKIM. Add them in Cloudflare DNS
   (see Cloudflare section below). Leave proxy status as **DNS only** (grey
   cloud) for these CNAME records.
5. Wait for SendGrid to verify the domain (usually a few minutes).

### 3. Configure sender address

Choose a from-address on your authenticated domain, e.g.:

```
MAILER_FROM=LandIQrd <noreply@landiqrd.com>
```

Store `MAILER_FROM` as a GitHub secret. `ApplicationMailer` reads this for
notification emails.

**Devise emails** (password reset, etc.) use a separate sender in
[`config/initializers/devise.rb`](config/initializers/devise.rb). Before going
live, update `config.mailer_sender` to the same address (or wire it to
`ENV["MAILER_FROM"]`) so all mail comes from your domain.

### 4. Set mail host

In [`config/deploy.yml`](config/deploy.yml), set `MAILER_HOST` under `env.clear`
to your public app hostname (same as `proxy.host`):

```yaml
env:
  clear:
    MAILER_HOST: app.landiqrd.com
```

This is used for links in emails (`lease_url`, password reset links, etc.).

### 5. Verify delivery

After deploy, trigger a password reset from the login page and confirm:

- The email arrives (check SendGrid **Activity** if it does not)
- Links point to `https://your-domain/...` not `example.com`
- The from-address matches your authenticated domain

---

## Cloudflare setup

Cloudflare provides DNS and proxies traffic to your EC2 instance. Kamal's built-in
proxy obtains a **Let's Encrypt** certificate on the origin.

### 1. Add your domain

1. Add the site to Cloudflare and update nameservers at your registrar.
2. Wait until the domain shows **Active** in Cloudflare.

### 2. DNS record for the app

Create an **A record** pointing at your EC2 public IP:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `app` (or `@` for apex) | `YOUR_EC2_PUBLIC_IP` | Proxied (orange cloud) |

Set `proxy.host` in [`config/deploy.yml`](config/deploy.yml) to match this
hostname (e.g. `app.landiqrd.com`).

If you use an **Elastic IP**, update the A record whenever the IP changes (or
use the Elastic IP from the start).

### 3. SSL/TLS mode

Kamal's proxy terminates HTTPS on the origin with Let's Encrypt. Cloudflare must
encrypt traffic to the origin as well.

1. Go to **SSL/TLS → Overview**.
2. Set encryption mode to **Full** (not Flexible).

   Use **Full (strict)** once Kamal has successfully issued the Let's Encrypt
   certificate on first deploy.

[`config/deploy.yml`](config/deploy.yml) documents this requirement in the
`proxy` section comments. After your first successful deploy, also uncomment
`config.assume_ssl` and `config.force_ssl` in
[`config/environments/production.rb`](config/environments/production.rb) and
set `config.hosts` to your domain.

### 4. SendGrid DNS records

When authenticating your domain in SendGrid, add the provided CNAME records in
**Cloudflare → DNS**:

- Set each record to **DNS only** (grey cloud). Proxying SendGrid CNAMEs
  through Cloudflare breaks verification.
- SendGrid may also provide an SPF TXT record or recommend one — add it at the
  root (`@`) if prompted.

### 5. Recommended Cloudflare settings

- **Always Use HTTPS** — On (SSL/TLS → Edge Certificates)
- **Minimum TLS Version** — 1.2
- **WebSockets** — On (required for Action Cable / Turbo Streams over `/cable`)

---

## GitHub Actions secrets

The deploy workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml))
runs `kamal deploy` on every push to `main`. Configure these repository secrets
(**Settings → Secrets and variables → Actions**):

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | PEM private key for EC2 SSH (entire file contents) |
| `RAILS_MASTER_KEY` | Contents of `config/master.key` |
| `KAMAL_REGISTRY_PASSWORD` | GitHub PAT with `write:packages` (for GHCR push/pull) |
| `DATABASE_URL` | Primary RDS connection string |
| `QUEUE_DATABASE_URL` | Queue RDS connection string |
| `AWS_ACCESS_KEY_ID` | S3 IAM access key |
| `AWS_SECRET_ACCESS_KEY` | S3 IAM secret key |
| `SENDGRID_API_KEY` | SendGrid API key |
| `MAILER_FROM` | Sender address, e.g. `LandIQrd <noreply@landiqrd.com>` |
| `REDIS_URL` | Redis connection string (if using real-time messaging) |

Consider gating deploy on CI passing (today deploy and CI both run on push to
`main` independently).

---

## Kamal configuration

Update placeholders in [`config/deploy.yml`](config/deploy.yml) before the first
deploy:

```yaml
image: your-github-owner/prop_man   # must match GHCR: ghcr.io/owner/repo

servers:
  web:
    - YOUR_EC2_PUBLIC_IP

proxy:
  ssl: true
  host: app.landiqrd.com            # must match Cloudflare A record

registry:
  username: your-github-owner

env:
  clear:
    MAILER_HOST: app.landiqrd.com
    AWS_REGION: us-east-1
    S3_BUCKET: landiqrd-production
```

Ensure [`/.kamal/secrets`](.kamal/secrets) references every secret listed under
`env.secret` in `deploy.yml`.

### First deploy

From your machine (with secrets exported or a populated `.kamal/secrets`):

```bash
bundle exec kamal setup    # first time only: Docker, proxy, registry auth
bundle exec kamal deploy
```

Or push to `main` and let GitHub Actions deploy.

`kamal setup` configures the Kamal proxy and requests a Let's Encrypt certificate
for `proxy.host`. The container runs `db:prepare` on boot to migrate the
database.

### Useful Kamal commands

```bash
bundle exec kamal logs -f          # tail production logs
bundle exec kamal app exec -i "bin/rails console"
bundle exec kamal app exec -i "bin/rails dbconsole --include-password"
```

Aliases for these are defined in `deploy.yml` (`bin/kamal console`, `bin/kamal logs`, etc.).

### Post-deploy verification

1. Visit `https://your-domain/up` — should return 200 (health check).
2. Sign up or log in with a seeded/admin account.
3. Trigger a password reset email and confirm SendGrid delivery.
4. Upload a photo on a work order and confirm it persists (S3).
5. Send a chat message between two users in the same conversation (Redis +
   Action Cable).

---

## Environment variables reference

| Variable | Required | Where set | Purpose |
|----------|----------|-----------|---------|
| `RAILS_MASTER_KEY` | Yes | Secret | Decrypts credentials |
| `DATABASE_URL` | Yes | Secret | Primary PostgreSQL |
| `QUEUE_DATABASE_URL` | Yes | Secret | Solid Queue database |
| `AWS_ACCESS_KEY_ID` | Yes | Secret | S3 uploads |
| `AWS_SECRET_ACCESS_KEY` | Yes | Secret | S3 uploads |
| `AWS_REGION` | Yes | `deploy.yml` clear | S3 region |
| `S3_BUCKET` | Yes | `deploy.yml` clear | S3 bucket name |
| `SENDGRID_API_KEY` | Yes | Secret | Outbound email |
| `MAILER_FROM` | Yes | Secret | Email from-address |
| `MAILER_HOST` | Yes | `deploy.yml` clear | Links in emails |
| `REDIS_URL` | Yes* | Secret | Action Cable (*for real-time chat) |
| `SOLID_QUEUE_IN_PUMA` | No | `deploy.yml` clear | Run jobs inside Puma (default `true`) |
| `RAILS_LOG_LEVEL` | No | `deploy.yml` clear | Log verbosity (default `info`) |
| `ACTIVE_STORAGE_SERVICE` | No | `deploy.yml` clear | Override storage backend |
