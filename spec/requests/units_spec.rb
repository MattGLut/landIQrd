require "rails_helper"

RSpec.describe "Units", type: :request do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }

  describe "GET /units/:id" do
    it "allows the owning landlord to view a unit" do
      unit = create(:unit, property: property)
      sign_in landlord
      get unit_path(unit)
      expect(response).to have_http_status(:ok)
    end

    it "blocks another landlord from viewing the unit" do
      unit = create(:unit, property: property)
      sign_in create(:landlord)
      get unit_path(unit)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /properties/:property_id/units" do
    it "creates a unit for the owning landlord" do
      sign_in landlord
      expect {
        post property_units_path(property), params: {
          unit: { label: "Apt 1A", bedrooms: 2, bathrooms: 1, square_feet: 850 }
        }
      }.to change(property.units, :count).by(1)
      expect(response).to redirect_to(property)
    end
  end

  describe "PATCH /units/:id" do
    it "updates a unit for the owning landlord" do
      unit = create(:unit, property: property, label: "Old label")
      sign_in landlord
      patch unit_path(unit), params: { unit: { label: "New label" } }
      expect(unit.reload.label).to eq("New label")
    end
  end

  describe "DELETE /units/:id" do
    it "removes a unit for the owning landlord" do
      unit = create(:unit, property: property)
      sign_in landlord
      expect {
        delete unit_path(unit)
      }.to change(Unit, :count).by(-1)
      expect(response).to redirect_to(property)
    end
  end
end
