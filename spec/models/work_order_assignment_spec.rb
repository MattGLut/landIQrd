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
end
