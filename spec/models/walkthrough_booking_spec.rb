require "rails_helper"

RSpec.describe WalkthroughBooking, type: :model do
  let(:job) { create(:job, :open) }
  let(:slot) { create(:walkthrough_slot, job: job, capacity: 1) }

  it "books a contractor into a slot" do
    expect(build(:walkthrough_booking, walkthrough_slot: slot)).to be_valid
  end

  it "refuses to overbook a slot" do
    create(:walkthrough_booking, walkthrough_slot: slot)
    other = build(:walkthrough_booking, walkthrough_slot: slot)
    expect(other).not_to be_valid
    expect(other.errors[:base].join).to match(/already booked/)
  end

  it "frees capacity after a cancellation" do
    booking = create(:walkthrough_booking, walkthrough_slot: slot)
    booking.cancel!
    expect(slot.reload).not_to be_full
    expect(build(:walkthrough_booking, walkthrough_slot: slot)).to be_valid
  end

  it "allows only one active booking per contractor per job" do
    contractor = create(:contractor)
    other_slot = create(:walkthrough_slot, job: job, starts_at: 4.days.from_now.change(min: 0))
    create(:walkthrough_booking, walkthrough_slot: slot, contractor: contractor)

    second = build(:walkthrough_booking, walkthrough_slot: other_slot, contractor: contractor)
    expect(second).not_to be_valid
    expect(second.errors[:base].join).to match(/already have a walkthrough/)
  end

  it "does not allow non-contractors" do
    expect(build(:walkthrough_booking, walkthrough_slot: slot, contractor: create(:tenant))).not_to be_valid
  end
end
