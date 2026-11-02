module Notifications
  class PhoneVerification
    EXPIRY = 10.minutes

    def self.send_code(user, phone:, consent:)
      return :disabled unless Sms.enabled?
      return :consent_required unless consent

      user.phone = phone
      user.validate
      if user.phone.blank?
        user.errors.add(:phone, "must be a valid phone number") unless user.errors[:phone].any?
        return :invalid
      end
      return :invalid if user.errors[:phone].any?

      code = format("%06d", SecureRandom.random_number(1_000_000))
      user.sms_consent_at = Time.current
      user.phone_verification_digest = digest(code)
      user.phone_verification_sent_at = Time.current
      unless user.save
        user.phone_verification_digest = nil
        user.phone_verification_sent_at = nil
        return :invalid
      end

      status = SmsClient.deliver(
        to: user.phone,
        body: "LandIQrd verification code: #{code}. It expires in 10 minutes."
      )
      user.update!(phone_verification_digest: nil, phone_verification_sent_at: nil) unless status == :sent
      status
    end

    def self.confirm(user, code)
      return :disabled unless Sms.enabled?
      if user.phone_verification_sent_at.present? && user.phone_verification_sent_at < EXPIRY.ago
        user.update!(phone_verification_digest: nil, phone_verification_sent_at: nil)
        return :expired
      end
      return :invalid unless fresh?(user)

      actual = digest(code.to_s.strip)
      expected = user.phone_verification_digest
      return :invalid unless expected.bytesize == actual.bytesize &&
        ActiveSupport::SecurityUtils.secure_compare(expected, actual)

      user.update!(
        phone_verified_at: Time.current,
        phone_verification_digest: nil,
        phone_verification_sent_at: nil
      )
      :confirmed
    end

    def self.digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "phone-verification:#{code}")
    end
    private_class_method :digest

    def self.fresh?(user)
      user.phone_verification_digest.present? &&
        user.phone_verification_sent_at.present? &&
        user.phone_verification_sent_at >= EXPIRY.ago
    end
    private_class_method :fresh?
  end
end
