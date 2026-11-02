class AddSmsFieldsToUsers < ActiveRecord::Migration[8.1]
  def up
    change_table :users, bulk: true do |t|
      t.datetime :phone_verified_at
      t.jsonb :sms_notification_preferences, null: false, default: {}
      t.datetime :sms_consent_at
      t.datetime :sms_opted_out_at
      t.string :phone_verification_digest
      t.datetime :phone_verification_sent_at
    end

    User.reset_column_information
    User.find_each do |user|
      next if user.phone.blank?

      parsed = Phonelib.parse(user.phone)
      normalized = parsed.possible? ? parsed.e164.presence : nil
      user.update_columns(phone: normalized) if user.phone != normalized
    end
  end

  def down
    change_table :users, bulk: true do |t|
      t.remove :phone_verified_at,
               :sms_notification_preferences,
               :sms_consent_at,
               :sms_opted_out_at,
               :phone_verification_digest,
               :phone_verification_sent_at
    end
  end
end
