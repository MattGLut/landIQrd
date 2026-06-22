require "rails_helper"

RSpec.describe Property, type: :model do
  it { is_expected.to belong_to(:landlord).class_name("User") }
  it { is_expected.to have_many(:units).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }

  describe "#full_address" do
    it "joins the present address parts" do
      property = build(:property, address_line1: "1 Main St", address_line2: nil, city: "Austin", state: "TX", postal_code: "78701")
      expect(property.full_address).to eq("1 Main St, Austin, TX, 78701")
    end
  end
end
