require "rails_helper"

RSpec.describe Devise::Mailer do
  it "sends password reset from the application sender" do
    user = create(:tenant)
    mail = described_class.reset_password_instructions(user, "raw-token")

    expect(mail.from).to eq([ "noreply@example.com" ])
    expect(mail.body.encoded).to include("Change my password")
  end

  it "notifies the user when the password changes" do
    user = create(:tenant)

    expect {
      user.reset_password("newpassword1", "newpassword1")
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    expect(ActionMailer::Base.deliveries.last.subject).to eq("Password Changed")
  end

  it "holds an email change until the new address is confirmed" do
    user = create(:tenant, email: "old@example.com")

    expect {
      user.update!(email: "new@example.com")
    }.to change { ActionMailer::Base.deliveries.size }.by(2)

    expect(user.reload.email).to eq("old@example.com")
    expect(user.unconfirmed_email).to eq("new@example.com")
    expect(ActionMailer::Base.deliveries.map(&:subject)).to include("Confirmation instructions", "Email Changed")
  end
end
