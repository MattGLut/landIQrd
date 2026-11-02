require "rails_helper"

RSpec.describe Notifications::SmsClient do
  it "does not call Twilio while SMS is disabled, even when credentials exist" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return("sid")
    allow(ENV).to receive(:[]).with("TWILIO_AUTH_TOKEN").and_return("token")
    allow(ENV).to receive(:[]).with("TWILIO_MESSAGING_SERVICE_SID").and_return("service")
    expect(Twilio::REST::Client).not_to receive(:new)

    expect(described_class.deliver(to: "+15125550100", body: "secret code 000111")).to eq(:disabled)
  end

  it "logs and skips when the flag is on but credentials are missing" do
    expect(Twilio::REST::Client).not_to receive(:new)

    with_sms_enabled do
      expect(described_class.deliver(to: "+15125550100", body: "secret code 000111")).to eq(:unconfigured)
    end
  end
end
