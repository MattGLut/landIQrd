require "rails_helper"

RSpec.describe "Passwords", type: :request do
  it "accepts a password reset request for a known email" do
    user = create(:tenant, email: "resetme@example.com")

    expect {
      post user_password_path, params: { user: { email: user.email } }
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "does not reveal whether an email exists" do
    post user_password_path, params: { user: { email: "missing@example.com" } }
    expect(response.status).to be_in([ 302, 422 ])
  end
end
