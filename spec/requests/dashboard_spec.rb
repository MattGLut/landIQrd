require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects guests to sign in" do
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)
  end

  %i[tenant landlord contractor].each do |role|
    it "renders the #{role} dashboard for a signed-in #{role}" do
      sign_in create(role)
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end

  it "redirects admins to the admin console" do
    sign_in create(:admin)
    get dashboard_path
    expect(response).to redirect_to(admin_dashboard_path)
  end

  describe "tenant dashboard data" do
    let(:tenant) { create(:tenant) }
    let(:landlord) { create(:landlord) }
    let(:property) { create(:property, landlord: landlord, name: "Oak Apartments") }
    let(:unit) { create(:unit, property: property, label: "2B") }

    before do
      create(:lease, unit: unit, tenant: tenant, status: :active)
      create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Broken heater")
      Conversation.direct_between!(tenant, landlord)
      sign_in tenant
    end

    it "renders active lease, work request, and conversation data" do
      get dashboard_path

      expect(response.body).to include("Oak Apartments &middot; 2B")
      expect(response.body).to include("Broken heater")
      expect(response.body).to include("1 active lease")
      expect(response.body).to include("1 active")
      expect(response.body).to include("Recent messages.")
    end

    it "excludes inactive leases from the dashboard" do
      ended_unit = create(:unit, property: create(:property, name: "Ended Place"))
      create(:lease, unit: ended_unit, tenant: tenant, status: :ended)
      draft_unit = create(:unit, property: create(:property, name: "Draft Place"))
      create(:lease, unit: draft_unit, tenant: tenant, status: :draft)

      get dashboard_path

      expect(response.body).to include("Oak Apartments &middot; 2B")
      expect(response.body).not_to include("Ended Place")
      expect(response.body).not_to include("Draft Place")
      expect(response.body).to include("1 active lease")
    end

    it "omits completed work orders from recent requests and lease tags" do
      create(:work_order, unit: unit, created_by: tenant, status: :completed, title: "Old repair")

      get dashboard_path

      expect(response.body).to include("Broken heater")
      expect(response.body).not_to include("Old repair")
      expect(response.body).to include("1 active")
    end
  end
end
