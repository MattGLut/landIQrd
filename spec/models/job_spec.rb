require "rails_helper"

RSpec.describe Job, type: :model do
  describe "validations" do
    it "is valid as a draft with minimal attributes" do
      expect(build(:job, description: nil, proposal_deadline: nil, trades: [])).to be_valid
    end

    it "rejects unknown trades" do
      job = build(:job, trades: %w[roofing wizardry])
      expect(job).not_to be_valid
      expect(job.errors[:trades]).to be_present
    end

    it "requires the creator to own the property" do
      job = build(:job, created_by: create(:landlord))
      expect(job).not_to be_valid
      expect(job.errors[:property]).to be_present
    end

    it "requires the unit to belong to the property" do
      job = build(:job, unit: create(:unit))
      expect(job).not_to be_valid
      expect(job.errors[:unit]).to be_present
    end

    it "rejects unsupported attachment types" do
      job = build(:job)
      job.attachments.attach(io: StringIO.new("x"), filename: "run.exe", content_type: "application/x-msdownload")
      expect(job).not_to be_valid
      expect(job.errors[:attachments].join).to match(/must be/)
    end

    it "accepts PDFs and images" do
      job = build(:job)
      job.attachments.attach(io: StringIO.new("%PDF-1.4"), filename: "scope.pdf", content_type: "application/pdf")
      expect(job).to be_valid
    end
  end

  describe "publish validations" do
    it "requires description, deadline and trades" do
      job = create(:job, description: nil, proposal_deadline: nil, trades: [])
      expect(job.valid?(:publish)).to be(false)
      expect(job.errors.attribute_names).to include(:description, :proposal_deadline, :trades)
    end

    it "rejects a past deadline" do
      job = create(:job, proposal_deadline: Date.current - 1)
      expect(job.valid?(:publish)).to be(false)
      expect(job.errors[:proposal_deadline]).to be_present
    end

    it "requires walkthrough slots when walkthroughs are required" do
      job = create(:job, :walkthrough_required)
      expect(job.valid?(:publish)).to be(false)
      expect(job.errors[:base].join).to match(/walkthrough/i)

      create(:walkthrough_slot, job: job)
      expect(job.reload.valid?(:publish)).to be(true)
    end

    it "publish! opens the job" do
      job = create(:job)
      job.publish!
      expect(job).to be_status_open
      expect(job.published_at).to be_present
    end

    it "publish! raises when invalid" do
      job = create(:job, description: nil)
      expect { job.publish! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#accepting_proposals?" do
    it "is false for drafts, past deadlines and closed jobs" do
      expect(build(:job)).not_to be_accepting_proposals
      expect(build(:job, :open, proposal_deadline: Date.current - 1)).not_to be_accepting_proposals
      expect(build(:job, :open, status: :closed)).not_to be_accepting_proposals
      expect(build(:job, :open)).to be_accepting_proposals
    end
  end

  describe ".matching_trades" do
    it "returns jobs sharing at least one trade" do
      roof = create(:job, :open, trades: %w[roofing general])
      create(:job, :open, trades: %w[plumbing])
      expect(described_class.matching_trades(%w[roofing])).to contain_exactly(roof)
      expect(described_class.matching_trades([])).to be_empty
    end
  end

  describe ".timezone_for_state" do
    it "uses the property's state instead of the Eastern default" do
      job = create(:job, property: create(:property, state: "TX"))
      expect(job.timezone).to eq("Central Time (US & Canada)")
    end

    it "keeps a timezone passed in explicitly" do
      job = create(:job, property: create(:property, state: "TX"), timezone: "Pacific Time (US & Canada)")
      expect(job.timezone).to eq("Pacific Time (US & Canada)")
    end
  end

  describe "#work_order_category" do
    it "uses the first trade that is a work order category" do
      expect(build(:job, trades: %w[roofing]).work_order_category).to eq("roofing")
      expect(build(:job, trades: []).work_order_category).to eq("general")
    end
  end
end
