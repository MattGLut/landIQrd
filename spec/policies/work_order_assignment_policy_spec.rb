require "rails_helper"

RSpec.describe WorkOrderAssignmentPolicy do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }
  let(:assignment) { create(:work_order_assignment, work_order: work_order, contractor: contractor) }

  def policy_for(user, record = assignment)
    described_class.new(user, record)
  end

  it "lets the owning landlord manage assignments" do
    expect(policy_for(landlord).create?).to be(true)
    expect(policy_for(landlord).destroy?).to be(true)
    expect(policy_for(landlord).update?).to be(true)
  end

  it "lets admins manage assignments" do
    expect(policy_for(create(:admin)).create?).to be(true)
    expect(policy_for(create(:admin)).destroy?).to be(true)
  end

  it "lets the assigned contractor update their assignment" do
    expect(policy_for(contractor).update?).to be(true)
    expect(policy_for(contractor).create?).to be(false)
    expect(policy_for(contractor).destroy?).to be(false)
  end

  it "forbids tenants from managing assignments" do
    expect(policy_for(tenant).create?).to be(false)
    expect(policy_for(tenant).destroy?).to be(false)
    expect(policy_for(tenant).update?).to be(false)
  end
end
