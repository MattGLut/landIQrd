require "rails_helper"

RSpec.describe Unit, type: :model do
  it { is_expected.to belong_to(:property) }
  it { is_expected.to have_many(:leases).dependent(:destroy) }
  it { is_expected.to have_many(:work_orders).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:label) }

  describe "#full_label" do
    it "includes the property name and unit label" do
      property = create(:property, name: "Oak Court")
      unit = create(:unit, property: property, label: "2B")

      expect(unit.full_label).to eq("Oak Court · 2B")
    end
  end

  describe "#effective_type" do
    it "inherits the property type by default" do
      property = create(:property, :commercial)
      unit = create(:unit, :commercial, property: property, unit_type: nil)
      expect(unit.effective_type).to eq("commercial")
    end

    it "uses the unit override when present" do
      property = create(:property, :commercial)
      unit = build(:unit, property: property, unit_type: :residential, bedrooms: 1, bathrooms: 1)
      expect(unit.effective_type).to eq("residential")
    end
  end

  describe "validations" do
    it "requires bedrooms and bathrooms for residential units" do
      unit = build(:unit, bedrooms: nil, bathrooms: nil)
      expect(unit).not_to be_valid
    end

    it "requires acreage for undeveloped units" do
      unit = build(:unit, :undeveloped, acreage: nil)
      expect(unit).not_to be_valid
    end

    it "requires use_class for commercial units" do
      unit = build(:unit, :commercial, features: {})
      expect(unit).not_to be_valid
      expect(unit.errors[:features]).to include("Use class is required")
    end

    it "clears residential fields for commercial units" do
      unit = create(:unit, :commercial)
      expect(unit.bedrooms).to be_nil
      expect(unit.bathrooms).to be_nil
    end
  end

  describe "#summary_line" do
    it "formats residential stats" do
      unit = build(:unit, bedrooms: 2, bathrooms: 1, square_feet: 850)
      expect(unit.summary_line).to eq("2 bd · 1 ba · 850 sqft")
    end

    it "formats commercial stats" do
      unit = build(:unit, :commercial)
      expect(unit.summary_line).to eq("Retail · 1500 sqft · 2 parking")
    end

    it "formats undeveloped stats" do
      unit = build(:unit, :undeveloped)
      expect(unit.summary_line).to eq("2.5 acres · R-1 · water/electric")
    end
  end

  describe "#active_lease" do
    it "returns the active lease when one exists" do
      unit = create(:unit)
      active = create(:lease, unit: unit, status: :active)
      create(:lease, unit: unit, status: :ended, start_date: 2.years.ago, end_date: 1.year.ago)

      expect(unit.active_lease).to eq(active)
    end
  end

  describe "#current_tenant" do
    it "returns the tenant on the active lease" do
      unit = create(:unit)
      tenant = create(:tenant)
      create(:lease, unit: unit, tenant: tenant, status: :active)

      expect(unit.current_tenant).to eq(tenant)
    end

    it "returns nil when there is no active lease" do
      unit = create(:unit)
      create(:lease, unit: unit, status: :ended, start_date: 2.years.ago, end_date: 1.year.ago)

      expect(unit.current_tenant).to be_nil
    end
  end
end
