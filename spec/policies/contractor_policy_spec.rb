require "rails_helper"

RSpec.describe ContractorPolicy do
  let(:contractor) { create(:contractor) }
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }

  def policy_for(user, record = contractor)
    described_class.new(user, record)
  end

  it "lets landlords browse contractors" do
    expect(policy_for(landlord).index?).to be(true)
    expect(policy_for(landlord).show?).to be(true)
  end

  it "lets admins browse contractors" do
    admin = create(:admin)
    expect(policy_for(admin).index?).to be(true)
    expect(policy_for(admin).show?).to be(true)
  end

  it "forbids tenants and contractors from browsing" do
    expect(policy_for(tenant).index?).to be(false)
    expect(policy_for(tenant).show?).to be(false)
    expect(policy_for(contractor).index?).to be(false)
    expect(policy_for(contractor).show?).to be(false)
  end

  describe "Scope" do
    it "returns contractors for landlords and admins only" do
      create(:contractor)
      create(:tenant)

      landlord_scope = described_class::Scope.new(landlord, User).resolve
      admin_scope = described_class::Scope.new(create(:admin), User).resolve
      tenant_scope = described_class::Scope.new(tenant, User).resolve

      expect(landlord_scope.contractor.count).to eq(User.contractor.count)
      expect(admin_scope.contractor.count).to eq(User.contractor.count)
      expect(tenant_scope).to be_empty
    end
  end
end
