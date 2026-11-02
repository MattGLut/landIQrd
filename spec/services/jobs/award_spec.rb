require "rails_helper"

RSpec.describe Jobs::Award do
  include ActiveJob::TestHelper

  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let!(:unit) { create(:unit, property: property) }
  let(:job) { create(:job, :open, property: property, trades: %w[roofing]) }
  let!(:winner) { create(:proposal, job: job, amount_cents: 500_000) }
  let!(:loser) { create(:proposal, job: job, amount_cents: 600_000) }

  after { clear_enqueued_jobs }

  it "creates a priced work order, assigns the contractor and closes out the job" do
    work_order = nil
    expect {
      work_order = described_class.call(job: job, proposal: winner, awarded_by: landlord)
    }.to change(WorkOrder, :count).by(1).and change(WorkOrderAssignment, :count).by(1)

    expect(work_order.unit).to eq(unit)
    expect(work_order.price_cents).to eq(500_000)
    expect(work_order.proposal).to eq(winner)
    expect(work_order.category).to eq("roofing")
    expect(work_order.contractors).to contain_exactly(winner.contractor)
    expect(work_order.work_order_assignments.first).to be_status_accepted

    expect(winner.reload).to be_awarded
    expect(loser.reload).to be_declined
    expect(job.reload).to be_status_awarded
    expect(job.work_order).to eq(work_order)
  end

  it "copies job photos to the work order" do
    job.attachments.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")), filename: "roof.png", content_type: "image/png")
    work_order = described_class.call(job: job, proposal: winner, awarded_by: landlord)
    expect(work_order.photos.count).to eq(1)
  end

  it "refuses to award a closed job" do
    job.close!
    expect { described_class.call(job: job, proposal: winner, awarded_by: landlord) }
      .to raise_error(Jobs::Award::Error, /no longer open/)
  end

  it "refuses a proposal from another job" do
    foreign = create(:proposal)
    expect { described_class.call(job: job, proposal: foreign, awarded_by: landlord) }
      .to raise_error(Jobs::Award::Error)
  end

  it "rolls back everything when the property has no unit" do
    unit.destroy!
    expect { described_class.call(job: job, proposal: winner, awarded_by: landlord) }
      .to raise_error(Jobs::Award::Error, /Add a unit/)
    expect(winner.reload).to be_submitted
    expect(job.reload).to be_status_open
  end
end
