require "rails_helper"

RSpec.describe WorkOrderPolicy do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let(:lease) { create(:lease, unit: unit, tenant: tenant) }
  let(:contractor) { create(:contractor) }
  let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }

  def policy_for(user)
    described_class.new(user, work_order)
  end

  it "lets the owning landlord see and manage it" do
    expect(policy_for(landlord).show?).to be(true)
    expect(policy_for(landlord).assign?).to be(true)
  end

  it "lets the creating tenant see it" do
    expect(policy_for(tenant).show?).to be(true)
    expect(policy_for(tenant).assign?).to be(false)
  end

  it "hides it from an unassigned contractor" do
    expect(policy_for(contractor).show?).to be(false)
  end

  it "shows it to an assigned contractor" do
    create(:work_order_assignment, work_order: work_order, contractor: contractor)
    work_order.reload
    expect(policy_for(contractor).show?).to be(true)
    expect(policy_for(contractor).update?).to be(true)
  end

  describe "scope" do
    it "limits a contractor to assigned work orders" do
      assigned = create(:work_order, unit: unit)
      create(:work_order_assignment, work_order: assigned, contractor: contractor)
      create(:work_order, unit: unit)
      resolved = WorkOrderPolicy::Scope.new(contractor, WorkOrder).resolve
      expect(resolved).to contain_exactly(assigned)
    end
  end
end
