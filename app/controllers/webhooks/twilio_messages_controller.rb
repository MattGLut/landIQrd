module Webhooks
  class TwilioMessagesController < ActionController::Base
    # Twilio posts from its own servers, so this endpoint cannot use a browser session or CSRF token.
    skip_forgery_protection

    STOP_KEYWORDS = %w[STOP STOPALL UNSUBSCRIBE CANCEL END QUIT].freeze
    START_KEYWORDS = %w[START UNSTOP YES].freeze

    def create
      unless Notifications::Sms.enabled?
        head :not_found
        return
      end

      unless valid_twilio_signature?
        head :forbidden
        return
      end

      user = User.find_by(phone: normalized_from)
      record_opt_out(user) if user
      head :ok
    end

    private

    def valid_twilio_signature?
      validator = Twilio::Security::RequestValidator.new(ENV["TWILIO_AUTH_TOKEN"].to_s)
      validator.validate(request.original_url, request.request_parameters, request.headers["X-Twilio-Signature"].to_s)
    end

    def normalized_from
      parsed = Phonelib.parse(params[:From].to_s)
      parsed.possible? ? parsed.e164.presence : params[:From].to_s
    end

    def record_opt_out(user)
      keyword = params[:Body].to_s.strip.upcase
      if STOP_KEYWORDS.include?(keyword)
        user.update!(sms_opted_out_at: Time.current, sms_notification_preferences: {})
      elsif START_KEYWORDS.include?(keyword)
        user.update!(sms_opted_out_at: nil)
      end
    end
  end
end
