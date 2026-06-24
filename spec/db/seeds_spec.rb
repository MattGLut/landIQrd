# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/support")

RSpec.describe "Seed builders" do
  describe Seeds::Support do
    let(:rng) { Random.new(42) }

    before do
      described_class.reset_state!
      described_class.state[:rng] = rng
    end

    describe ".build_property_features" do
      it "returns valid residential property features" do
        features = described_class.build_property_features(:residential)
        property = build(:property, features: features)
        expect(property).to be_valid
      end

      it "returns valid commercial property features" do
        features = described_class.build_property_features(:commercial)
        property = build(:property, :commercial, features: features)
        expect(property).to be_valid
      end
    end

    describe ".build_unit_features" do
      it "includes use_class for commercial units" do
        features = described_class.build_unit_features(:commercial)
        unit = build(:unit, :commercial, features: features.merge("use_class" => "retail"))
        expect(unit).to be_valid
      end

      it "returns valid undeveloped unit features" do
        features = described_class.build_unit_features(:undeveloped)
        unit = build(:unit, :undeveloped, features: features.merge("zoning" => "R-1"))
        expect(unit).to be_valid
      end
    end

    describe ".work_order_category_for" do
      it "returns a category allowed for the unit type" do
        unit = build(:unit, :commercial)
        category = described_class.work_order_category_for(unit)
        expect(WorkOrder.categories_for(unit)).to include(category)
      end

      it "returns land categories for undeveloped units" do
        unit = build(:unit, :undeveloped)
        category = described_class.work_order_category_for(unit)
        expect(WorkOrder.categories_for(unit)).to include(category)
      end
    end

    describe ".occupancy_scenario" do
      it "cycles through tenancy scenarios" do
        scenarios = 13.times.map { |index| described_class.occupancy_scenario(index) }
        expect(scenarios).to include(:active, :vacant, :invitation_pending)
      end
    end
  end
end
