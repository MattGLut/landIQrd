require "rails_helper"

RSpec.describe Proposal, type: :model do
  describe "#amount" do
    it "converts dollars to cents and back" do
      proposal = described_class.new
      proposal.amount = "$2,450.50"
      expect(proposal.amount_cents).to eq(245_050)
      expect(proposal.amount).to eq(2450.5)
    end

    it "clears the amount for blank or invalid input" do
      proposal = described_class.new(amount_cents: 100)
      proposal.amount = "abc"
      expect(proposal.amount_cents).to be_nil
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:proposal)).to be_valid
    end

    it "limits scope and exclusions to 500 characters" do
      proposal = build(:proposal, scope: "a" * 501, exclusions: "b" * 501)
      expect(proposal).not_to be_valid
      expect(proposal.errors.attribute_names).to include(:scope, :exclusions)
    end

    it "requires a positive amount" do
      expect(build(:proposal, amount_cents: 0)).not_to be_valid
    end

    it "allows one proposal per contractor per job" do
      existing = create(:proposal)
      duplicate = build(:proposal, job: existing.job, contractor: existing.contractor)
      expect(duplicate).not_to be_valid
    end

    it "rejects proposals once the job is closed" do
      job = create(:job, :open, status: :closed)
      expect(build(:proposal, job: job)).not_to be_valid
    end

    it "requires a booked walkthrough when the job demands one" do
      job = create(:job, :open, :walkthrough_required)
      slot = create(:walkthrough_slot, job: job, capacity: 2)
      contractor = create(:contractor, trades: %w[roofing])

      expect(build(:proposal, job: job, contractor: contractor)).not_to be_valid

      create(:walkthrough_booking, walkthrough_slot: slot, contractor: contractor)
      expect(build(:proposal, job: job, contractor: contractor)).to be_valid
    end

    it "rejects unsupported attachment types" do
      proposal = build(:proposal)
      proposal.attachments.attach(io: StringIO.new("x"), filename: "a.zip", content_type: "application/zip")
      expect(proposal).not_to be_valid
    end
  end

  describe "#withdraw!" do
    it "marks a submitted proposal withdrawn" do
      proposal = create(:proposal)
      proposal.withdraw!
      expect(proposal).to be_withdrawn
    end
  end
end
