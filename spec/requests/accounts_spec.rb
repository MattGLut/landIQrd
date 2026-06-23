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
  end
end
