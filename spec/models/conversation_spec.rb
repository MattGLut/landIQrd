require "rails_helper"

RSpec.describe Conversation, type: :model do
  it { is_expected.to belong_to(:work_order).optional }
  it { is_expected.to have_many(:messages).dependent(:destroy) }
  it { is_expected.to have_many(:participants).through(:conversation_participants) }

  describe ".for_work_order!" do
    let(:landlord) { create(:landlord) }
    let(:property) { create(:property, landlord: landlord) }
    let(:unit) { create(:unit, property: property) }
    let(:tenant) { create(:tenant) }
    let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }

    it "creates one thread and includes creator and landlord" do
      conversation = described_class.for_work_order!(work_order)
      expect(conversation.participants).to include(tenant, landlord)
    end

    it "is idempotent" do
      first = described_class.for_work_order!(work_order)
      second = described_class.for_work_order!(work_order)
      expect(first).to eq(second)
    end

    it "adds contractors as they are assigned" do
      contractor = create(:contractor)
      create(:work_order_assignment, work_order: work_order, contractor: contractor)
      work_order.reload
      conversation = described_class.for_work_order!(work_order)
      expect(conversation.participants).to include(contractor)
    end
  end

  describe ".direct_between!" do
    it "reuses an existing direct thread" do
      a = create(:tenant)
      b = create(:landlord)
      first = described_class.direct_between!(a, b)
      second = described_class.direct_between!(b, a)
      expect(first).to eq(second)
    end
  end
end
