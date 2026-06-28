require "rails_helper"

RSpec.describe ContractorPortfolioItemPolicy do
  let(:contractor) { create(:contractor) }
  let(:other_contractor) { create(:contractor) }
  let(:item) { create(:contractor_portfolio_item, contractor: contractor) }

  def policy_for(user, record = item)
    described_class.new(user, record)
  end

  it "lets the owning contractor manage their portfolio" do
    expect(policy_for(contractor).index?).to be(true)
    expect(policy_for(contractor).create?).to be(true)
    expect(policy_for(contractor).update?).to be(true)
    expect(policy_for(contractor).destroy?).to be(true)
  end

  it "forbids other users from managing portfolio items" do
    expect(policy_for(other_contractor).update?).to be(false)
    expect(policy_for(other_contractor).destroy?).to be(false)
    expect(policy_for(create(:landlord)).update?).to be(false)
  end
end
