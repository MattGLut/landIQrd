require "rails_helper"

RSpec.describe WorkOrders::TransitionStatus do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:work_order) { create(:work_order, unit: unit, status: :open) }

  it "allows valid transitions" do
    described_class.call(work_order: work_order, to: :in_progress, user: landlord)

    expect(work_order.reload).to be_status_in_progress
    expect(work_order.work_order_events.last.action).to eq("status_changed")
  end

  it "rejects invalid transitions" do
    work_order.update!(status: :completed)

    expect {
      described_class.call(work_order: work_order, to: :open, user: landlord)
    }.to raise_error(WorkOrders::TransitionStatus::InvalidTransition)
  end
end
