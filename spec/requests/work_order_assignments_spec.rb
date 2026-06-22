require "rails_helper"

RSpec.describe "WorkOrderAssignments", type: :request do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }

  describe "PATCH /work_orders/:work_order_id/work_order_assignments/:id" do
    it "lets the assigned contractor update the assignment" do
      assignment = create(:work_order_assignment, work_order: work_order, contractor: contractor, status: :accepted)
      sign_in contractor
      patch work_order_work_order_assignment_path(work_order, assignment),
            params: { work_order_assignment: { status: "completed" } }
      expect(assignment.reload).to be_status_completed
    end
  end

  describe "DELETE /work_orders/:work_order_id/work_order_assignments/:id" do
    it "lets the landlord remove an assignment" do
      assignment = create(:work_order_assignment, work_order: work_order, contractor: contractor)
      sign_in landlord
      expect {
        delete work_order_work_order_assignment_path(work_order, assignment)
      }.to change(WorkOrderAssignment, :count).by(-1)
      expect(response).to redirect_to(work_order)
    end

    it "forbids a contractor from removing an assignment" do
      assignment = create(:work_order_assignment, work_order: work_order, contractor: contractor)
      sign_in contractor
      delete work_order_work_order_assignment_path(work_order, assignment)
      expect(WorkOrderAssignment.count).to eq(1)
    end
  end
end
