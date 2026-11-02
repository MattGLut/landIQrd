require "rails_helper"

RSpec.describe JobPolicy do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:job) { create(:job, :open, property: property, trades: %w[roofing]) }
  let(:roofer) { create(:contractor, trades: %w[roofing]) }
  let(:plumber) { create(:contractor, trades: %w[plumbing]) }

  describe "owners" do
    it "lets the owning landlord manage, update and close" do
      policy = described_class.new(landlord, job)
      expect(policy.manage?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.close?).to be(true)
      expect(policy.bid?).to be(false)
    end

    it "does not let another landlord manage the job" do
      expect(described_class.new(create(:landlord), job).manage?).to be(false)
    end

    it "only publishes and deletes drafts" do
      draft = create(:job, property: property)
      expect(described_class.new(landlord, draft).publish?).to be(true)
      expect(described_class.new(landlord, draft).destroy?).to be(true)
      expect(described_class.new(landlord, job).publish?).to be(false)
      expect(described_class.new(landlord, job).destroy?).to be(false)
    end
  end

  describe "contractors" do
    it "can bid on open jobs matching their trades" do
      expect(described_class.new(roofer, job).bid?).to be(true)
      expect(described_class.new(plumber, job).bid?).to be(false)
    end

    it "cannot bid after the deadline" do
      job.update!(proposal_deadline: Date.current - 1)
      expect(described_class.new(roofer, job).bid?).to be(false)
    end

    it "cannot see drafts" do
      draft = create(:job, property: property)
      expect(described_class.new(roofer, draft).show?).to be(false)
    end
  end

  describe "Scope" do
    it "limits landlords to their own jobs" do
      mine = job
      create(:job, :open)
      expect(Pundit.policy_scope(landlord, Job)).to contain_exactly(mine)
    end

    it "shows contractors matching open jobs and ones they bid on, never drafts" do
      matching = job
      other = create(:job, :open, trades: %w[plumbing])
      create(:job, property: property, trades: %w[roofing]) # draft
      bid_on = create(:job, :open, trades: %w[painting])
      create(:proposal, job: bid_on, contractor: roofer)

      expect(Pundit.policy_scope(roofer, Job)).to contain_exactly(matching, bid_on)
      expect(Pundit.policy_scope(roofer, Job)).not_to include(other)
    end
  end
end
