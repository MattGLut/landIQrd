module Notifications
  class SmsClient
    def self.deliver(to:, body:)
      return :disabled unless Sms.enabled?
      unless configured?
        Rails.logger.info("SMS not sent because Twilio credentials are missing")
        return :unconfigured
      end

      client.messages.create(
        messaging_service_sid: ENV["TWILIO_MESSAGING_SERVICE_SID"],
        to: to,
        body: body
      )
      :sent
    rescue Twilio::REST::RestError => error
      Rails.logger.error("SMS delivery failed (#{error.status_code})")
      :failed
    end

    def self.configured?
      ENV["TWILIO_ACCOUNT_SID"].present? &&
        ENV["TWILIO_AUTH_TOKEN"].present? &&
        ENV["TWILIO_MESSAGING_SERVICE_SID"].present?
    end

    def self.client
      Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
    end
    private_class_method :client
  end
end
