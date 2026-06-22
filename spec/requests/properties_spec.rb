require "rails_helper"

RSpec.describe "Properties", type: :request do
  let(:landlord) { create(:landlord) }

  describe "GET /properties" do
    it "lists only the landlord's own properties" do
      mine = create(:property, landlord: landlord, name: "Mine")
      create(:property, name: "Theirs")
      sign_in landlord

      get properties_path
      expect(response.body).to include("Mine")
      expect(response.body).not_to include("Theirs")
    end

    it "forbids tenants" do
      sign_in create(:tenant)
      get properties_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /properties" do
    it "creates a property owned by the current landlord" do
      sign_in landlord
      expect {
        post properties_path, params: { property: { name: "Maple Court" } }
      }.to change(landlord.properties, :count).by(1)
      expect(response).to redirect_to(Property.last)
    end
  end

  describe "PATCH /properties/:id" do
    it "updates a property owned by the current landlord" do
      property = create(:property, landlord: landlord, name: "Old name")
      sign_in landlord
      patch property_path(property), params: { property: { name: "New name" } }
      expect(property.reload.name).to eq("New name")
    end
  end

  describe "DELETE /properties/:id" do
    it "deletes a property owned by the current landlord" do
      property = create(:property, landlord: landlord)
      sign_in landlord
      expect {
        delete property_path(property)
      }.to change(landlord.properties, :count).by(-1)
      expect(response).to redirect_to(properties_path)
    end
  end
end
