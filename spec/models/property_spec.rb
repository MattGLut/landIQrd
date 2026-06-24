require "rails_helper"

RSpec.describe Property, type: :model do
  it { is_expected.to belong_to(:landlord).class_name("User") }
  it { is_expected.to have_many(:units).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }

  it do
    is_expected.to define_enum_for(:property_type)
      .with_values(residential: 0, commercial: 1, undeveloped: 2)
  end

  describe "#full_address" do
    it "joins the present address parts" do
      property = build(:property, address_line1: "1 Main St", address_line2: nil, city: "Austin", state: "TX", postal_code: "78701")
      expect(property.full_address).to eq("1 Main St, Austin, TX, 78701")
    end
  end

  describe "features" do
    it "accepts valid residential property features" do
      property = build(:property, features: { "parking" => "garage", "pool" => true })
      expect(property).to be_valid
      expect(property.feature_value("pool")).to eq(true)
    end

    it "rejects invalid enum feature values" do
      property = build(:property, features: { "parking" => "helicopter_pad" })
      expect(property).not_to be_valid
      expect(property.errors[:features]).to be_present
    end

    it "strips features that do not apply to the property type" do
      property = create(:property, :commercial, features: { "pool" => true, "ada_accessible" => true })
      expect(property.features.keys).to contain_exactly("ada_accessible")
    end
  end

  describe "#units_with_type_overrides?" do
    it "returns true when a unit overrides the property type" do
      property = create(:property, :commercial)
      create(:unit, property: property, unit_type: :residential, bedrooms: 1, bathrooms: 1)
      expect(property.units_with_type_overrides?).to be(true)
    end
  end
end
