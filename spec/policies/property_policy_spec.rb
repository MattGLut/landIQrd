require "rails_helper"

RSpec.describe PropertyPolicy do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }

  def policy_for(user)
    described_class.new(user, property)
  end

  it "lets the owning landlord manage the property" do
    policy = policy_for(landlord)
    expect(policy.show?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
    expect(policy.index?).to be(true)
  end

  it "forbids a different landlord from touching it" do
    policy = policy_for(create(:landlord))
    expect(policy.show?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it "forbids tenants entirely" do
    policy = policy_for(create(:tenant))
    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
  end

  it "permits admins" do
    policy = policy_for(create(:admin))
    expect(policy.show?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  describe "scope" do
    it "returns only the landlord's properties" do
      mine = create(:property, landlord: landlord)
      create(:property)
      resolved = PropertyPolicy::Scope.new(landlord, Property).resolve
      expect(resolved).to contain_exactly(mine, property)
    end

    it "returns nothing for a tenant" do
      create(:property)
      resolved = PropertyPolicy::Scope.new(create(:tenant), Property).resolve
      expect(resolved).to be_empty
    end
  end
end
