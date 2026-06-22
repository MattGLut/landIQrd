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
      expect(WorkOrder.last.work_order_events.last.action).to eq("created")
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

    it "rejects invalid status transitions" do
      work_order = create(:work_order, unit: unit, created_by: tenant, status: :completed)
      sign_in landlord
      patch work_order_path(work_order), params: { work_order: { status: "open" } }
      expect(work_order.reload).to be_status_completed
      expect(response).to redirect_to(edit_work_order_path(work_order))
    end

    it "logs detail updates as work order events" do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Old title")
      sign_in tenant
      patch work_order_path(work_order), params: { work_order: { title: "New title" } }
      expect(work_order.work_order_events.last.action).to eq("updated")
    end
  end

  describe "POST /work_orders/:id/close" do
    it "lets the creating tenant close with a reason" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      sign_in tenant
      post close_work_order_path(work_order), params: { closure_reason: "No longer needed" }
      expect(work_order.reload).to be_status_cancelled
      expect(work_order.closure_reason).to eq("No longer needed")
      expect(response).to redirect_to(work_order_path(work_order))
    end

    it "forbids landlords from using the tenant close action" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      sign_in landlord
      post close_work_order_path(work_order), params: { closure_reason: "Done" }
      expect(work_order.reload).to be_status_open
    end
  end

  describe "DELETE /work_orders/:id" do
    it "lets the landlord delete a work order" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      sign_in landlord
      expect {
        delete work_order_path(work_order)
      }.to change(WorkOrder, :count).by(-1)
    end

    it "forbids the creating tenant from deleting" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      sign_in tenant
      delete work_order_path(work_order)
      expect(WorkOrder.exists?(work_order.id)).to be(true)
    end
  end

  describe "GET /work_orders/schedule" do
    it "shows scheduled assignments for the landlord" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      assignment = create(
        :work_order_assignment,
        work_order: work_order,
        scheduled_at: 2.days.from_now
      )

      sign_in landlord
      get schedule_work_orders_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(work_order.title)
      expect(response.body).to include(assignment.contractor.display_name)
    end

    it "forbids tenants from viewing the schedule" do
      sign_in tenant
      get schedule_work_orders_path
      expect(response).to redirect_to(root_path)
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
