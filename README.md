# Prop Man

A property management app for small (1-15 unit) landlords. Tenants, landlords,
contractors, and admins collaborate around leases, work requests, and messaging.

## Stack

- Ruby on Rails 8 (Hotwire: Turbo + Stimulus), server-rendered.
- PostgreSQL, Devise (auth), Pundit (authorization).
- ActiveStorage (local disk in dev/test, S3 in staging/production).
- Solid Queue / Solid Cache / Solid Cable.
- RSpec, FactoryBot, Capybara, SimpleCov.
- Deploy via Kamal (Docker) to a single EC2 host + RDS + S3; CI via GitHub Actions.

## Local setup

```bash
bundle install            # gems install into vendor/bundle (see .bundle/config)
bin/rails db:prepare      # create + migrate
bin/dev                   # boots Puma + Tailwind watcher
```

Always run tooling through Bundler (`bundle exec ...`) because gems are vendored.

### Roles

`User#role` is an enum: `tenant`, `landlord`, `contractor`, `admin`. Self
sign-up is limited to tenant/landlord/contractor; admins are created via the
admin console or the console.

## Running the test suite

```bash
bundle exec rspec
bundle exec rubocop
bin/brakeman
```

## File storage (S3)

Dev/test use local disk. Staging/production use S3 via `config/storage.yml`,
configured entirely from environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (default `us-east-1`)
- `S3_BUCKET`

`config.active_storage.service` defaults to `:amazon` in production (override
with `ACTIVE_STORAGE_SERVICE=local`).

### Required S3 / IAM setup

1. Create a private S3 bucket (e.g. `prop-man-production`).
2. Create an IAM user (or, preferably, an instance role on the EC2 host) scoped
   to that bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::prop-man-production",
        "arn:aws:s3:::prop-man-production/*"
      ]
    }
  ]
}
```

3. Provide the credentials/region/bucket via the environment variables above.

## Deployment

See `config/deploy.yml` (Kamal) and `.github/workflows/`. Production also needs
`DATABASE_URL` (RDS) and `RAILS_MASTER_KEY`.
