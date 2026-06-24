# Idempotent demo/dev seed data. Safe to run repeatedly.
# Default password for every seeded account is "password123".
#
# Rebuild the full demo dataset:
#   FORCE_SEED=1 bundle exec rails db:seed
# PowerShell: $env:FORCE_SEED = "1"; bundle exec rails db:seed
#
# One-time staging seed (production DB, explicit opt-in):
#   ALLOW_DEMO_SEED=1 FORCE_SEED=1 bin/rails db:seed

require_relative "seeds/support"

unless Seeds::Support.demo_seed_allowed?
  puts "Skipping seeds in #{Rails.env}."
  puts "Set ALLOW_DEMO_SEED=1 to seed a production/staging database (one-time demo data)."
  return
end

if Rails.env.production? && ENV["ALLOW_DEMO_SEED"] == "1"
  puts "ALLOW_DEMO_SEED=1 — loading demo data into #{Rails.env}…"
end

if Rails.env.test?
  puts "Skipping seeds in the test environment."
  return
end

require_relative "seeds/accounts"
require_relative "seeds/portfolios"
require_relative "seeds/tenancy"
require_relative "seeds/operations"

if Seeds::Support.already_seeded? && !Seeds::Support.force_reseed?
  Seeds::Support.print_skipped_summary
  return
end

Seeds::Support.silence_side_effects do
  Seeds::Support.prepare!
  Seeds::Accounts.seed!
  Seeds::Portfolios.seed!
  Seeds::Tenancy.seed!
  Seeds::Operations.seed!
end

Seeds::Support.print_summary
