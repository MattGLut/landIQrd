require "rails_helper"

RSpec.describe WorkOrderAssignment, type: :model do
  it { is_expected.to belong_to(:work_order) }
  it { is_expected.to belong_to(:contractor).class_name("User") }

  it "requires a unique contractor per work order" do
    assignment = create(:work_order_assignment)
    duplicate = build(:work_order_assignment, work_order: assignment.work_order, contractor: assignment.contractor)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:contractor_id]).to be_present
  end

  it "requires the assignee to be a contractor" do
    assignment = build(:work_order_assignment, contractor: create(:tenant))

    expect(assignment).not_to be_valid
    expect(assignment.errors[:contractor]).to include("must be a contractor")
  end

  describe "callbacks" do
    include ActiveJob::TestHelper

    after { clear_enqueued_jobs }

    it "syncs the work order conversation and notifies the contractor" do
      work_order = create(:work_order)
      contractor = create(:contractor)

      expect {
        create(:work_order_assignment, work_order: work_order, contractor: contractor)
      }.to change { Conversation.where(work_order: work_order).count }.by(1)
        .and have_enqueued_mail(NotificationMailer, :contractor_assigned)

      conversation = Conversation.find_by!(work_order: work_order)
      expect(conversation.participants).to include(contractor)
    end
  end
end
