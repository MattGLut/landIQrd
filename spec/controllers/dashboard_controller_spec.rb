require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  describe "GET #show" do
    context "as a tenant" do
      let(:tenant) { create(:tenant) }
      let(:landlord) { create(:landlord) }
      let(:property) { create(:property, landlord: landlord, name: "Oak Apartments") }
      let(:unit) { create(:unit, property: property, label: "2B") }
      let!(:active_lease) { create(:lease, unit: unit, tenant: tenant, status: :active) }
      let!(:open_work_order) { create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Broken heater") }
      let!(:conversation) { Conversation.direct_between!(tenant, landlord) }

      before { sign_in tenant }

      it "loads recent leases, work orders, conversations, and unit work order counts" do
        get :show

        expect(assigns(:leases_count)).to eq(1)
        expect(assigns(:recent_leases)).to contain_exactly(active_lease)
        expect(assigns(:open_work_orders_count)).to eq(1)
        expect(assigns(:recent_open_work_orders)).to contain_exactly(open_work_order)
        expect(assigns(:recent_conversations)).to contain_exactly(conversation)
        expect(assigns(:active_work_order_counts_by_unit_id)).to eq({ unit.id => 1 })
        expect(assigns(:conversations_count)).to eq(1)
        expect(assigns(:expiring_leases)).to eq([])
      end

      it "excludes inactive leases from recent leases" do
        ended_unit = create(:unit, property: create(:property, name: "Ended Place"))
        create(:lease, unit: ended_unit, tenant: tenant, status: :ended)
        draft_unit = create(:unit, property: create(:property, name: "Draft Place"))
        create(:lease, unit: draft_unit, tenant: tenant, status: :draft)

        get :show

        expect(assigns(:leases_count)).to eq(1)
        expect(assigns(:recent_leases).map { |lease| lease.unit.property.name }).to eq([ "Oak Apartments" ])
      end

      it "counts only active work orders for lease tags and recent requests" do
        create(:work_order, unit: unit, created_by: tenant, status: :completed, title: "Old repair")

        get :show

        expect(assigns(:open_work_orders_count)).to eq(1)
        expect(assigns(:recent_open_work_orders)).to contain_exactly(open_work_order)
        expect(assigns(:active_work_order_counts_by_unit_id)).to eq({ unit.id => 1 })
      end
    end
  end
end
