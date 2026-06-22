require "rails_helper"

RSpec.describe MessagePolicy do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:conversation) { Conversation.direct_between!(tenant, landlord) }
  let(:message) { conversation.messages.new(author: tenant) }

  def policy_for(user)
    described_class.new(user, message)
  end

  it "allows conversation participants to post messages" do
    expect(policy_for(tenant).create?).to be(true)
    expect(policy_for(landlord).create?).to be(true)
  end

  it "allows admins to post messages" do
    expect(policy_for(create(:admin)).create?).to be(true)
  end

  it "forbids non-participants from posting messages" do
    expect(policy_for(contractor).create?).to be(false)
  end
end
