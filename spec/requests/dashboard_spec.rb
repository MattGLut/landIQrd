require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects guests to sign in" do
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)
  end

  %i[tenant landlord contractor admin].each do |role|
    it "renders the #{role} dashboard for a signed-in #{role}" do
      sign_in create(role)
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
