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

    it "creates an undeveloped unit with acreage and features" do
      land_property = create(:property, :undeveloped, landlord: landlord)
      sign_in landlord
      post property_units_path(land_property), params: {
        unit: {
          label: "Lot A",
          acreage: 3.25,
          features: { zoning: "R-1", water_hookup: "1", sewer_hookup: "0" }
        }
      }
      unit = land_property.units.last
      expect(unit.acreage).to eq(3.25)
      expect(unit.feature_value("zoning")).to eq("R-1")
      expect(unit.feature_value("water_hookup")).to eq(true)
      expect(unit.feature_value("sewer_hookup")).to eq(false)
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
