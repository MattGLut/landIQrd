module Notifications
  class SendSmsJob < ApplicationJob
    queue_as :default

    def perform(user_id, body)
      return unless Sms.enabled?

      user = User.find_by(id: user_id)
      return if user.nil? || !user.sms_deliverable?

      SmsClient.deliver(to: user.phone, body: body)
    end
  end
end
