require "rails_helper"

RSpec.describe "Contractor marketplace", type: :request do
  include ActiveJob::TestHelper

  let(:contractor) { create(:contractor, trades: %w[roofing], service_city: "Austin", service_state: "TX") }
  let(:property) { create(:property, city: "Austin", state: "TX") }
  let!(:unit) { create(:unit, property: property) }
  let(:job) { create(:job, :open, property: property, trades: %w[roofing]) }
  let(:proposal_params) do
    { proposal: { amount: "2,450", scope: "Fix it", exclusions: "Paint", earliest_start: (Date.current + 4).to_s, estimated_duration_days: 3 } }
  end

  before { sign_in contractor }
  after { clear_enqueued_jobs }

  describe "My trades" do
    it "saves trades and service area" do
      patch contractor_trades_path, params: { user: { trades: [ "", "painting", "hvac" ], service_city: "Dallas", service_state: "TX", service_radius_miles: 75, notify_matching_jobs: "0" } }

      expect(response).to redirect_to(contractor_trades_path)
      contractor.reload
      expect(contractor.trades).to match_array(%w[painting hvac])
      expect(contractor.service_city).to eq("Dallas")
      expect(contractor.service_radius_miles).to eq(75)
      expect(contractor.notify_matching_jobs).to be(false)
    end

    it "lists matching opportunities" do
      job
      get contractor_trades_path
      expect(response.body).to include(job.title)
    end

    it "rejects unknown trades" do
      patch contractor_trades_path, params: { user: { trades: [ "juggling" ] } }
      expect(contractor.reload.trades).to eq(%w[roofing])
    end
  end

  describe "Find work" do
    it "lists only matching open jobs" do
      job
      other = create(:job, :open, trades: %w[plumbing], title: "Plumbing thing")

      get contractor_available_jobs_path

      expect(response.body).to include(job.title)
      expect(response.body).not_to include(other.title)
    end

    it "shows a job to a matching contractor and hides it from others" do
      get contractor_available_job_path(job)
      expect(response).to have_http_status(:ok)

      other = create(:job, :open, trades: %w[plumbing])
      get contractor_available_job_path(other)
      expect(response).not_to have_http_status(:ok)
    end
  end

  describe "walkthroughs" do
    let!(:slot) { create(:walkthrough_slot, job: job, capacity: 1) }

    it "books and cancels a slot" do
      expect {
        post contractor_available_job_walkthrough_bookings_path(job), params: { slot_id: slot.id }
      }.to change(WalkthroughBooking.confirmed, :count).by(1)

      get contractor_walkthrough_bookings_path
      expect(response.body).to include(job.title)

      booking = WalkthroughBooking.last
      delete contractor_walkthrough_booking_path(booking)
      expect(booking.reload).to be_cancelled
    end

    it "does not double book a full slot" do
      create(:walkthrough_booking, walkthrough_slot: slot)
      expect {
        post contractor_available_job_walkthrough_bookings_path(job), params: { slot_id: slot.id }
      }.not_to change(WalkthroughBooking, :count)
    end
  end

  describe "proposals" do
    it "submits a proposal and notifies the landlord" do
      expect {
        post contractor_available_job_proposals_path(job), params: proposal_params
      }.to change(Proposal, :count).by(1)

      proposal = Proposal.last
      expect(proposal.amount_cents).to eq(245_000)
      expect(proposal.contractor).to eq(contractor)
      expect(response).to redirect_to(contractor_proposal_path(proposal))
    end

    it "blocks proposals until the required walkthrough is booked" do
      job.update!(walkthrough_required: true)
      slot = create(:walkthrough_slot, job: job)

      expect {
        post contractor_available_job_proposals_path(job), params: proposal_params
      }.not_to change(Proposal, :count)

      create(:walkthrough_booking, walkthrough_slot: slot, contractor: contractor)
      expect {
        post contractor_available_job_proposals_path(job), params: proposal_params
      }.to change(Proposal, :count).by(1)
    end

    it "does not let a contractor bid outside their trades" do
      plumbing_job = create(:job, :open, trades: %w[plumbing])
      expect {
        post contractor_available_job_proposals_path(plumbing_job), params: proposal_params
      }.not_to change(Proposal, :count)
    end

    it "edits and withdraws a proposal" do
      proposal = create(:proposal, job: job, contractor: contractor)

      patch contractor_proposal_path(proposal), params: { proposal: { amount: "1999" } }
      expect(proposal.reload.amount_cents).to eq(199_900)

      post withdraw_contractor_proposal_path(proposal)
      expect(proposal.reload).to be_withdrawn
    end

    it "lists and shows own proposals only" do
      mine = create(:proposal, job: job, contractor: contractor)
      theirs = create(:proposal, job: job)

      get contractor_proposals_path
      expect(response.body).to include(contractor_proposal_path(mine))
      expect(response.body).not_to include(contractor_proposal_path(theirs))

      get contractor_proposal_path(theirs)
      expect(response).not_to have_http_status(:ok)
    end
  end
end
