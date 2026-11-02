require "rails_helper"

RSpec.describe "Twilio inbound messages", type: :request do
  let!(:user) { create(:tenant, phone: "+15125550199", sms_notification_preferences: { "new_message" => true }) }

  it "does nothing while SMS is disabled" do
    expect(Twilio::Security::RequestValidator).not_to receive(:new)

    post "/twilio/messages", params: { From: user.phone, Body: "STOP" }

    expect(response).to have_http_status(:not_found)
    expect(user.reload.sms_opted_out_at).to be_nil
  end

  it "records STOP and START when the signature is valid" do
    validator = instance_double(Twilio::Security::RequestValidator, validate: true)
    allow(Twilio::Security::RequestValidator).to receive(:new).and_return(validator)

    with_sms_enabled do
      post "/twilio/messages", params: { From: "5125550199", Body: "stop" }
      expect(response).to have_http_status(:ok)
      expect(user.reload.sms_opted_out_at).to be_present
      expect(user.sms_notification_preferences).to eq({})

      post "/twilio/messages", params: { From: user.phone, Body: "START" }
      expect(user.reload.sms_opted_out_at).to be_nil
    end
  end

  it "rejects a bad signature" do
    validator = instance_double(Twilio::Security::RequestValidator, validate: false)
    allow(Twilio::Security::RequestValidator).to receive(:new).and_return(validator)

    with_sms_enabled do
      post "/twilio/messages", params: { From: user.phone, Body: "STOP" }
    end

    expect(response).to have_http_status(:forbidden)
    expect(user.reload.sms_opted_out_at).to be_nil
  end
end
