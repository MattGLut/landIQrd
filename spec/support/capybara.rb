require "capybara/rspec"

RSpec.configure do |config|
  # Default to the fast rack_test driver; opt into a JS-capable driver per example
  # with `js: true` for flows that depend on Turbo Streams / Stimulus.
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
