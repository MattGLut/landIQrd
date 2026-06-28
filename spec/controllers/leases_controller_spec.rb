require "rails_helper"

RSpec.describe LeasesController, type: :controller do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:linked_tenant) { create(:tenant, first_name: "Alice", last_name: "Anderson") }
  let(:invited_tenant) { create(:tenant, email: "invited@example.com", first_name: "Bob", last_name: "Baker") }
  let(:unrelated_tenant) { create(:tenant, first_name: "Zoe", last_name: "Zimmerman") }

  describe "GET #new" do
    context "as a landlord" do
      before do
        create(:lease, unit: unit, tenant: linked_tenant, status: :active)
        create(:lease_invitation, unit: unit, email: invited_tenant.email, invited_by: landlord)
        sign_in landlord
      end

      it "loads linked and invited tenants and excludes unrelated tenants" do
        get :new, params: { unit_id: unit.id }

        expect(assigns(:tenants)).to contain_exactly(linked_tenant, invited_tenant)
        expect(assigns(:tenants)).not_to include(unrelated_tenant)
      end
    end

    context "as an admin" do
      before do
        linked_tenant
        invited_tenant
        unrelated_tenant
        sign_in create(:admin)
      end

      it "loads all tenants ordered by name" do
        get :new, params: { unit_id: unit.id }

        expect(assigns(:tenants)).to eq(User.tenant.order(:last_name, :first_name).to_a)
      end
    end
  end

  describe "GET #edit" do
    let!(:lease) { create(:lease, unit: unit, tenant: linked_tenant, status: :active) }

    before do
      create(:lease_invitation, unit: unit, email: invited_tenant.email, invited_by: landlord)
      sign_in landlord
    end

    it "loads tenants through the same before_action as new" do
      get :edit, params: { id: lease.id }

      expect(assigns(:tenants)).to contain_exactly(linked_tenant, invited_tenant)
    end
  end
end
