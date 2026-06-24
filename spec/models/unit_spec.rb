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
