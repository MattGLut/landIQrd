require "rails_helper"

RSpec.describe LeasePolicy do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let(:lease) { create(:lease, unit: unit, tenant: tenant) }

  def policy_for(user)
    described_class.new(user, lease)
  end

  it "lets the owning landlord manage the lease" do
    policy = policy_for(landlord)
    expect(policy.show?).to be(true)
    expect(policy.update?).to be(true)
  end

  it "gives the tenant read-only access" do
    policy = policy_for(tenant)
    expect(policy.show?).to be(true)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it "forbids an unrelated tenant" do
    expect(policy_for(create(:tenant)).show?).to be(false)
  end

  describe "scope" do
    it "scopes leases to the tenant" do
      lease
      create(:lease)
      resolved = LeasePolicy::Scope.new(tenant, Lease).resolve
      expect(resolved).to contain_exactly(lease)
    end

    it "scopes leases to the landlord's portfolio" do
      lease
      create(:lease)
      resolved = LeasePolicy::Scope.new(landlord, Lease).resolve
      expect(resolved).to contain_exactly(lease)
    end
  end
end
