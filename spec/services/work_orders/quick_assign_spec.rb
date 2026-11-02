require "rails_helper"

RSpec.describe WorkOrders::QuickAssign do
  let(:landlord) { create(:landlord) }
  let(:contractor) { create(:contractor, company_name: "FixIt Co") }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let!(:relationship) { create_relationship }

  def create_relationship
    ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :personal, status: :accepted)
  end

  def quick_job(overrides = {})
    QuickJob.new({
      contractor_id: contractor.id,
      unit_id: unit.id,
      title: "Replace the faucet",
      description: "Kitchen sink faucet is loose.",
      category: "plumbing",
      priority: "high",
      price: "250"
    }.merge(overrides))
  end

  it "creates a pending assignment and skips the proposal flow" do
    work_order = described_class.call(landlord: landlord, quick_job: quick_job)

    expect(work_order).to be_persisted
    expect(work_order.proposal).to be_nil
    expect(work_order.price_cents).to eq(25_000)
    expect(work_order.category).to eq("plumbing")
    expect(work_order.priority).to eq("high")
    expect(work_order.created_by).to eq(landlord)

    assignment = work_order.work_order_assignments.sole
    expect(assignment.contractor).to eq(contractor)
    expect(assignment).to be_status_pending

    event = work_order.work_order_events.find_by!(action: "assigned")
    expect(event.description).to include("sent this job directly to FixIt Co")
    expect(event.description).to include("personal contact")
    expect(work_order.conversation).to be_present
  end

  it "refuses a contact who has not accepted" do
    relationship.update!(status: :pending)

    expect { described_class.call(landlord: landlord, quick_job: quick_job) }
      .to raise_error(described_class::Error, /has not accepted/)
    expect(WorkOrder.count).to eq(0)
  end

  it "refuses a contractor who is not a saved contact" do
    relationship.destroy!

    expect { described_class.call(landlord: landlord, quick_job: quick_job) }
      .to raise_error(described_class::Error, /personal or business contact/)
    expect(WorkOrder.count).to eq(0)
  end

  it "refuses a unit owned by another landlord" do
    other_unit = create(:unit)

    expect { described_class.call(landlord: landlord, quick_job: quick_job(unit_id: other_unit.id)) }
      .to raise_error(described_class::Error, /your units/)
    expect(WorkOrder.where(unit: other_unit)).to be_empty
  end
end
