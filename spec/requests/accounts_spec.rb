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
end
