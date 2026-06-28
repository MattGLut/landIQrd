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

  describe ".expiring_within" do
    it "returns active leases ending within the given number of days" do
      unit = create(:unit)
      expiring_soon = create(
        :lease,
        unit: unit,
        status: :active,
        end_date: 2.weeks.from_now.to_date
      )
      create(:lease, unit: create(:unit), status: :active, end_date: 6.months.from_now.to_date)
      create(:lease, unit: create(:unit), status: :ended, end_date: 1.week.from_now.to_date)
      create(:lease, unit: create(:unit), status: :active, end_date: nil)

      expect(Lease.expiring_within(60)).to contain_exactly(expiring_soon)
    end

    it "excludes leases ending after the window" do
      create(:lease, status: :active, end_date: 3.months.from_now.to_date)

      expect(Lease.expiring_within(30)).to be_empty
    end
  end

  describe "#expiring_soon?" do
    it "returns true for active leases ending within the default window" do
      lease = create(:lease, status: :active, end_date: 2.weeks.from_now.to_date)

      expect(lease.expiring_soon?).to be(true)
    end

    it "returns false for open-ended or inactive leases" do
      expect(create(:lease, status: :active, end_date: nil).expiring_soon?).to be(false)
      expect(create(:lease, status: :ended, end_date: 1.week.from_now.to_date).expiring_soon?).to be(false)
    end
  end
end
