module Notifications
  module Sms
    def self.enabled?
      ENV["SMS_ENABLED"] == "true"
    end
  end
end
