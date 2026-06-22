require "rails_helper"

RSpec.describe Lease, type: :model do
  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:tenant).class_name("User") }
  it { is_expected.to validate_presence_of(:start_date) }

  it do
    is_expected.to define_enum_for(:status)
      .with_values(draft: 0, active: 1, ended: 2, terminated: 3)
  end

  it "is invalid when end_date precedes start_date" do
    lease = build(:lease, start_date: Date.current, end_date: Date.current - 1.day)
    expect(lease).not_to be_valid
    expect(lease.errors[:end_date]).to be_present
  end

  it "delegates landlord to the unit's property" do
    lease = create(:lease)
    expect(lease.landlord).to eq(lease.unit.property.landlord)
  end
end
