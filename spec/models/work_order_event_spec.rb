require "rails_helper"

RSpec.describe WorkOrderEvent, type: :model do
  let(:user) { create(:tenant, first_name: "Toni", last_name: "Tenant") }
  let(:work_order) { create(:work_order, created_by: user) }

  it { is_expected.to belong_to(:work_order) }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_presence_of(:action) }

  describe "#description" do
    it "describes creation" do
      event = described_class.create!(work_order: work_order, user: user, action: "created")
      expect(event.description).to include("Toni Tenant")
      expect(event.description).to include("submitted")
    end

    it "describes status changes" do
      event = described_class.create!(
        work_order: work_order,
        user: user,
        action: "status_changed",
        metadata: { "from" => "open", "to" => "pending_management" }
      )
      expect(event.description).to include("Open")
      expect(event.description).to include("Pending management")
    end

    it "describes tenant closure with reason" do
      event = described_class.create!(
        work_order: work_order,
        user: user,
        action: "closed",
        metadata: { "closure_reason" => "Fixed it myself" }
      )
      expect(event.description).to include("closed this request")
      expect(event.description).to include("Fixed it myself")
    end

    it "describes field updates" do
      event = described_class.create!(
        work_order: work_order,
        user: user,
        action: "updated",
        metadata: { "changes" => { "title" => [ "Old", "New" ] } }
      )
      expect(event.description).to include("Title")
    end

    it "falls back to System when user is nil" do
      event = described_class.create!(work_order: work_order, user: nil, action: "created")
      expect(event.description).to start_with("System")
    end
  end
end
