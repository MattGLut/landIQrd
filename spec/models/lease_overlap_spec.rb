require "rails_helper"

RSpec.describe Lease, type: :model do
  it "prevents more than one active lease per unit" do
    unit = create(:unit)
    create(:lease, unit: unit, status: :active)
    duplicate = build(:lease, unit: unit, status: :active)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:unit]).to include("already has an active lease")
  end
end
