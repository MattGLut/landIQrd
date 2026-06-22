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
    expect(policy_for(contractor).update?).to be(false)
    expect(policy_for(contractor).edit_details?).to be(false)
  end

  it "allows the creating tenant to edit details and close active requests" do
    expect(policy_for(tenant).edit_details?).to be(true)
    expect(policy_for(tenant).close?).to be(true)
    expect(policy_for(tenant).change_status?).to be(false)
    expect(policy_for(tenant).destroy?).to be(false)
  end

  it "allows the landlord to change status and close" do
    expect(policy_for(landlord).change_status?).to be(true)
    expect(policy_for(landlord).close?).to be(true)
    expect(policy_for(landlord).destroy?).to be(false)
  end

  it "allows admins to delete and close work orders" do
    admin = create(:admin)
    expect(policy_for(admin).destroy?).to be(true)
    expect(policy_for(admin).close?).to be(true)
  end

  it "forbids close once the work order is terminal" do
    work_order.update!(status: :cancelled)
    expect(policy_for(tenant).close?).to be(false)
  end

  describe "reopen?" do
    before { work_order.update!(status: :completed) }

    it "allows the creating tenant, landlord, and admin to reopen completed work orders" do
      expect(policy_for(tenant).reopen?).to be(true)
      expect(policy_for(landlord).reopen?).to be(true)
      expect(policy_for(create(:admin)).reopen?).to be(true)
    end

    it "forbids contractors and non-creator tenants from reopening" do
      other_unit = create(:unit, property: property)
      other_tenant = create(:tenant)
      create(:lease, unit: other_unit, tenant: other_tenant)
      create(:work_order_assignment, work_order: work_order, contractor: contractor)
      work_order.reload

      expect(policy_for(contractor).reopen?).to be(false)
      expect(policy_for(other_tenant).reopen?).to be(false)
    end

    it "forbids reopen once the work order is no longer completed" do
      work_order.update!(status: :open)
      expect(policy_for(tenant).reopen?).to be(false)
    end
  end

  it "allows schedule access for landlords and contractors" do
    expect(described_class.new(landlord, WorkOrder).schedule?).to be(true)
    expect(described_class.new(contractor, WorkOrder).schedule?).to be(true)
    expect(described_class.new(tenant, WorkOrder).schedule?).to be(false)
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
