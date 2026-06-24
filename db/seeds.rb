# Idempotent demo/dev seed data. Safe to run repeatedly.
# Default password for every seeded account is "password123".
#
# Rebuild the full demo dataset:
#   FORCE_SEED=1 bundle exec rails db:seed
# PowerShell: $env:FORCE_SEED = "1"; bundle exec rails db:seed

if Rails.env.production?
  puts "Skipping seeds in production."
  return
end

if Rails.env.test?
  puts "Skipping seeds in the test environment."
  return
end

require_relative "seeds/support"
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
