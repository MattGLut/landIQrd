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

    context "as a landlord" do
      let(:landlord) { create(:landlord) }
      let(:tenant) { create(:tenant) }
      let(:property) { create(:property, landlord: landlord, name: "Maple Court") }
      let(:unit) { create(:unit, property: property) }
      let!(:lease) { create(:lease, unit: unit, tenant: tenant, status: :active) }
      let!(:open_work_order) { create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Leaky faucet") }
      let!(:conversation) { Conversation.direct_between!(tenant, landlord) }

      before { sign_in landlord }

      it "loads property, work order, tenant, and conversation data" do
        get :show

        expect(assigns(:properties_count)).to eq(1)
        expect(assigns(:recent_properties)).to contain_exactly(property)
        expect(assigns(:open_work_orders_count)).to eq(1)
        expect(assigns(:recent_open_work_orders)).to contain_exactly(open_work_order)
        expect(assigns(:tenants_count)).to eq(1)
        expect(assigns(:recent_tenant_leases).map(&:tenant_id)).to eq([ tenant.id ])
        expect(assigns(:recent_conversations)).to contain_exactly(conversation)
        expect(assigns(:conversations_count)).to eq(1)
        expect(assigns(:expiring_leases)).to eq([])
      end

      it "limits recent properties to six" do
        7.times { |index| create(:property, landlord: landlord, name: "Property #{index}") }

        get :show

        expect(assigns(:properties_count)).to eq(8)
        expect(assigns(:recent_properties).size).to eq(6)
      end

      it "excludes completed work orders from open work order data" do
        create(:work_order, unit: unit, created_by: tenant, status: :completed, title: "Old repair")

        get :show

        expect(assigns(:open_work_orders_count)).to eq(1)
        expect(assigns(:recent_open_work_orders)).to contain_exactly(open_work_order)
      end

      it "loads expiring leases within ninety days" do
        expiring_lease = create(
          :lease,
          unit: create(:unit, property: create(:property, landlord: landlord, name: "Sunset Apts"), label: "3C"),
          tenant: tenant,
          status: :active,
          end_date: 3.weeks.from_now.to_date
        )

        get :show

        expect(assigns(:expiring_leases)).to contain_exactly(expiring_lease)
      end

      it "counts each tenant once when they have multiple active leases" do
        second_unit = create(:unit, property: property, label: "2A")
        create(:lease, unit: second_unit, tenant: tenant, status: :active)

        get :show

        expect(assigns(:tenants_count)).to eq(1)
        expect(assigns(:recent_tenant_leases).map(&:tenant_id).uniq).to eq([ tenant.id ])
      end

      it "sets unread conversation count from helper" do
        conversation.messages.create!(author: tenant, body: "Can we schedule a visit?")

        get :show

        expect(assigns(:unread_conversations_count)).to eq(1)
      end
    end

    context "as a contractor" do
      let(:contractor) { create(:contractor) }
      let(:landlord) { create(:landlord) }
      let(:property) { create(:property, landlord: landlord) }
      let(:unit) { create(:unit, property: property) }
      let!(:assigned_work_order) do
        work_order = create(:work_order, unit: unit, title: "Fix broken pipe", status: :open)
        create(:work_order_assignment, work_order: work_order, contractor: contractor)
        work_order
      end
      let!(:conversation) { Conversation.direct_between!(landlord, contractor) }

      before { sign_in contractor }

      it "loads assigned active work orders and conversations" do
        get :show

        expect(assigns(:assigned_work_orders_count)).to eq(1)
        expect(assigns(:recent_assigned_work_orders)).to contain_exactly(assigned_work_order)
        expect(assigns(:recent_conversations)).to include(conversation)
        expect(assigns(:conversations_count)).to eq(2)
      end

      it "excludes unassigned and completed work orders" do
        create(:work_order, unit: unit, title: "Someone elses job", status: :open)
        completed = create(:work_order, unit: unit, title: "Finished job", status: :completed)
        create(:work_order_assignment, work_order: completed, contractor: contractor)

        get :show

        expect(assigns(:assigned_work_orders_count)).to eq(1)
        expect(assigns(:recent_assigned_work_orders)).to contain_exactly(assigned_work_order)
      end
    end

    context "as an admin" do
      let(:admin) { create(:admin) }

      before do
        create(:landlord)
        create(:tenant)
        create(:property)
        create(:work_order)
        sign_in admin
      end

      it "redirects to the admin console" do
        get :show

        expect(response).to redirect_to(admin_dashboard_path)
      end
    end
  end
end
