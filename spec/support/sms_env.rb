module SmsEnv
  def with_sms_enabled
    previous = ENV["SMS_ENABLED"]
    ENV["SMS_ENABLED"] = "true"
    yield
  ensure
    ENV["SMS_ENABLED"] = previous
  end
end

RSpec.configure do |config|
  config.include SmsEnv
end
