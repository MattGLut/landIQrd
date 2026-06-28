require "rails_helper"

RSpec.describe WorkOrdersController, type: :controller do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }

  describe "GET #index" do
    let!(:open_work_order) { create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Open job") }
    let!(:completed_work_order) { create(:work_order, unit: unit, created_by: tenant, status: :completed, title: "Done job") }

    before { sign_in landlord }

    it "assigns all work orders when no status filter is provided" do
      get :index

      expect(assigns(:status_filter)).to be_nil
      expect(assigns(:work_orders)).to contain_exactly(open_work_order, completed_work_order)
    end

    it "filters to active work orders when status is active" do
      get :index, params: { status: "active" }

      expect(assigns(:status_filter)).to eq("active")
      expect(assigns(:work_orders)).to contain_exactly(open_work_order)
    end

    it "scopes work orders to the contractor's assignments" do
      contractor = create(:contractor)
      assigned = create(:work_order, unit: unit, title: "Assigned job")
      create(:work_order_assignment, work_order: assigned, contractor: contractor)
      create(:work_order, unit: unit, title: "Someone elses job")

      sign_in contractor
      get :index

      expect(assigns(:work_orders)).to contain_exactly(assigned)
    end
  end

  describe "GET #schedule" do
    let(:contractor) { create(:contractor) }
    let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }
    let!(:scheduled_assignment) do
      create(:work_order_assignment, work_order: work_order, contractor: contractor, scheduled_at: 2.days.from_now)
    end
    let!(:unscheduled_assignment) do
      other_work_order = create(:work_order, unit: unit, created_by: tenant)
      create(:work_order_assignment, work_order: other_work_order, contractor: contractor, scheduled_at: nil)
    end

    it "shows scheduled assignments for the landlord's properties" do
      other_landlord = create(:landlord)
      other_property = create(:property, landlord: other_landlord)
      other_unit = create(:unit, property: other_property)
      other_work_order = create(:work_order, unit: other_unit)
      create(:work_order_assignment, work_order: other_work_order, contractor: contractor, scheduled_at: 1.day.from_now)

      sign_in landlord
      get :schedule

      expect(assigns(:assignments)).to contain_exactly(scheduled_assignment)
    end

    it "shows only the contractor's own scheduled assignments" do
      sign_in contractor
      get :schedule

      expect(assigns(:assignments)).to contain_exactly(scheduled_assignment)
    end
  end

  describe "GET #new" do
    it "limits units to those leased by the tenant" do
      other_unit = create(:unit)

      sign_in tenant
      get :new

      expect(assigns(:units)).to contain_exactly(unit)
      expect(assigns(:units)).not_to include(other_unit)
    end

    it "limits units to the landlord's properties" do
      other_landlord = create(:landlord)
      other_unit = create(:unit, property: create(:property, landlord: other_landlord))

      sign_in landlord
      get :new

      expect(assigns(:units)).to contain_exactly(unit)
      expect(assigns(:units)).not_to include(other_unit)
    end
  end

  describe "GET #show" do
    let(:work_order) { create(:work_order, unit: unit, created_by: tenant, title: "Original title") }

    before { sign_in landlord }

    it "assigns work order events in chronological order" do
      updated = WorkOrders::RecordEvent.call(
        work_order: work_order,
        user: landlord,
        action: "updated",
        metadata: { "changes" => {} }
      )
      status_changed = WorkOrders::RecordEvent.call(
        work_order: work_order,
        user: landlord,
        action: "status_changed",
        metadata: {}
      )
      created = work_order.work_order_events.find_by!(action: "created")
      created.update_column(:created_at, 3.hours.ago)
      updated.update_column(:created_at, 2.hours.ago)
      status_changed.update_column(:created_at, 1.hour.ago)

      get :show, params: { id: work_order.id }

      expect(assigns(:events).map(&:action)).to eq([ "created", "updated", "status_changed" ])
    end
  end
end
