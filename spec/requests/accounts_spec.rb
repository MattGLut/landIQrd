require "rails_helper"

RSpec.describe "Accounts", type: :request do
  let(:tenant) { create(:tenant) }

  it "updates the current user's profile" do
    sign_in tenant
    patch account_path, params: { user: { preferred_name: "Preferred" } }

    expect(response).to redirect_to(edit_account_path)
    expect(tenant.reload.preferred_name).to eq("Preferred")
  end

  it "requires authentication" do
    patch account_path, params: { user: { preferred_name: "Nope" } }
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "notification preferences" do
    it "updates the current user's email notification preferences" do
      sign_in tenant
      patch notifications_account_path, params: {
        user: {
          email_notification_preferences: {
            work_order_status_changed: "1",
            new_message: "0",
            lease_expiring: "0"
          }
        }
      }

      expect(response).to redirect_to(notifications_account_path)
      expect(tenant.reload.email_notification_preferences).to eq(
        "work_order_status_changed" => true,
        "new_message" => false,
        "lease_expiring" => false
      )
    end

    it "requires authentication" do
      patch notifications_account_path, params: {
        user: { email_notification_preferences: { new_message: "0" } }
      }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "hides text notifications while SMS is disabled" do
      sign_in tenant
      get notifications_account_path

      expect(response.body).not_to include("Text messages")
    end

    it "updates text preferences after the phone is verified" do
      sign_in tenant
      with_sms_enabled do
        tenant.update!(
          phone: "+15125550199",
          phone_verified_at: Time.current,
          sms_consent_at: Time.current
        )
        get notifications_account_path
        expect(response.body).to include("Text messages")

        patch sms_notifications_account_path, params: {
          user: {
            sms_notification_preferences: {
              work_order_status_changed: "0",
              new_message: "1",
              lease_expiring: "0"
            }
          }
        }
      end

      expect(response).to redirect_to(notifications_account_path)
      expect(tenant.reload.sms_notification_preferences).to eq(
        "work_order_status_changed" => false,
        "new_message" => true,
        "lease_expiring" => false
      )
    end
  end

  describe "phone verification" do
    it "does not send a code while SMS is disabled" do
      sign_in tenant
      post phone_verification_account_path, params: {
        user: { phone: "512-555-0199" },
        sms_consent: "1"
      }

      expect(response).to have_http_status(:not_found)
      expect(tenant.reload.phone_verification_digest).to be_nil
    end

    it "verifies a consented number when SMS is enabled" do
      sign_in tenant
      allow(SecureRandom).to receive(:random_number).with(1_000_000).and_return(42)
      allow(Notifications::SmsClient).to receive(:deliver).and_return(:sent)

      with_sms_enabled do
        post phone_verification_account_path, params: {
          user: { phone: "512-555-0199" },
          sms_consent: "1"
        }
        expect(response).to redirect_to(notifications_account_path)
        expect(Notifications::SmsClient).to have_received(:deliver).with(
          hash_including(to: "+15125550199", body: a_string_including("000042"))
        )

        patch phone_verification_account_path, params: { verification_code: "000042" }
      end

      expect(response).to redirect_to(notifications_account_path)
      expect(tenant.reload.phone_verified_at).to be_present
      expect(tenant.phone_verification_digest).to be_nil
    end
  end
end
