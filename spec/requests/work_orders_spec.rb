require "rails_helper"

RSpec.describe "WorkOrders", type: :request do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }

  describe "GET /work_orders" do
    it "shows a contractor only their assigned work orders" do
      contractor = create(:contractor)
      assigned = create(:work_order, unit: unit, title: "Assigned job")
      create(:work_order_assignment, work_order: assigned, contractor: contractor)
      create(:work_order, unit: unit, title: "Someone elses job")

      sign_in contractor
      get work_orders_path
      expect(response.body).to include("Assigned job")
      expect(response.body).not_to include("Someone elses job")
    end
  end

  describe "POST /work_orders" do
    it "lets a tenant create a request on a unit they lease" do
      sign_in tenant
      expect {
        post work_orders_path, params: { work_order: { unit_id: unit.id, title: "No heat", priority: "high" } }
      }.to change(WorkOrder, :count).by(1)
      expect(WorkOrder.last.created_by).to eq(tenant)
      expect(WorkOrder.last).to be_status_open
    end

    it "rejects a tenant creating a request on a unit they do not lease" do
      other_unit = create(:unit)
      sign_in tenant
      post work_orders_path, params: { work_order: { unit_id: other_unit.id, title: "Sneaky" } }
      expect(WorkOrder.where(title: "Sneaky")).to be_empty
    end
  end

  describe "PATCH /work_orders/:id" do
    it "lets the landlord change the status" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      sign_in landlord
      patch work_order_path(work_order), params: { work_order: { status: "in_progress" } }
      expect(work_order.reload).to be_status_in_progress
    end
  end

  describe "assignments" do
    let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }
    let(:contractor) { create(:contractor) }

    it "lets the landlord assign a contractor" do
      sign_in landlord
      expect {
        post work_order_work_order_assignments_path(work_order),
             params: { work_order_assignment: { contractor_id: contractor.id } }
      }.to change(WorkOrderAssignment, :count).by(1)
    end

    it "forbids a tenant from assigning a contractor" do
      sign_in tenant
      post work_order_work_order_assignments_path(work_order),
           params: { work_order_assignment: { contractor_id: contractor.id } }
      expect(WorkOrderAssignment.count).to eq(0)
    end
  end
end
