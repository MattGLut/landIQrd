require "rails_helper"

RSpec.describe ConversationPolicy do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:conversation) { Conversation.direct_between!(tenant, landlord) }

  def policy_for(user, record = conversation)
    described_class.new(user, record)
  end

  it "allows any signed-in user to list conversations" do
    expect(policy_for(tenant).index?).to be(true)
    expect(policy_for(contractor).index?).to be(true)
  end

  it "allows participants and admins to view a thread" do
    expect(policy_for(tenant).show?).to be(true)
    expect(policy_for(landlord).show?).to be(true)
    expect(policy_for(create(:admin)).show?).to be(true)
  end

  it "forbids non-participants from viewing a thread" do
    expect(policy_for(contractor).show?).to be(false)
  end

  it "allows all roles to create conversations" do
    expect(policy_for(tenant).create?).to be(true)
    expect(policy_for(landlord).create?).to be(true)
    expect(policy_for(contractor).create?).to be(true)
  end

  describe "scope" do
    it "returns only conversations the user participates in" do
      mine = Conversation.direct_between!(tenant, landlord)
      Conversation.direct_between!(create(:tenant), create(:landlord))

      resolved = ConversationPolicy::Scope.new(tenant, Conversation).resolve
      expect(resolved).to contain_exactly(mine)
    end

    it "returns all conversations for admins" do
      first = Conversation.direct_between!(tenant, landlord)
      second = Conversation.direct_between!(create(:tenant), create(:landlord))

      resolved = ConversationPolicy::Scope.new(create(:admin), Conversation).resolve
      expect(resolved).to contain_exactly(first, second)
    end
  end
end
