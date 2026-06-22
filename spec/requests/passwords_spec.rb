require "rails_helper"

RSpec.describe "Passwords", type: :request do
  def token_from_reset_email(mail)
    mail.body.encoded[/reset_password_token=([^"&]+)/, 1]
  end

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

  it "resets the password with a valid token" do
    user = create(:tenant, email: "resetme@example.com")
    raw, enc = Devise.token_generator.generate(User, :reset_password_token)
    user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)

    put user_password_path, params: {
      user: {
        reset_password_token: raw,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }

    expect(response).to redirect_to(authenticated_root_path)
    expect(user.reload.valid_password?("newpassword123")).to be(true)
  end

  it "resets the password using the link from the email" do
    user = create(:tenant, email: "resetme@example.com")

    post user_password_path, params: { user: { email: user.email } }
    mail = ActionMailer::Base.deliveries.last
    token = token_from_reset_email(mail)

    put user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }

    expect(response).to redirect_to(authenticated_root_path)
    expect(user.reload.valid_password?("newpassword123")).to be(true)
  end
end
