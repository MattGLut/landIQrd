require "rails_helper"

RSpec.describe UnitPolicy do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }

  def policy_for(user, record = unit)
    described_class.new(user, record)
  end

  it "lets the owning landlord manage the unit" do
    expect(policy_for(landlord).show?).to be(true)
    expect(policy_for(landlord).create?).to be(true)
    expect(policy_for(landlord).update?).to be(true)
    expect(policy_for(landlord).destroy?).to be(true)
  end

  it "forbids a different landlord from managing the unit" do
    expect(policy_for(create(:landlord)).show?).to be(false)
    expect(policy_for(create(:landlord)).update?).to be(false)
  end

  it "forbids tenants from managing units" do
    expect(policy_for(create(:tenant)).show?).to be(false)
    expect(policy_for(create(:tenant)).create?).to be(false)
  end

  it "permits admins" do
    expect(policy_for(create(:admin)).show?).to be(true)
    expect(policy_for(create(:admin)).destroy?).to be(true)
  end

  describe "scope" do
    it "returns only the landlord's units" do
      mine = create(:unit, property: property)
      create(:unit)

      resolved = UnitPolicy::Scope.new(landlord, Unit).resolve
      expect(resolved).to contain_exactly(mine, unit)
    end

    it "returns nothing for a tenant" do
      create(:unit)
      resolved = UnitPolicy::Scope.new(create(:tenant), Unit).resolve
      expect(resolved).to be_empty
    end
  end
end
