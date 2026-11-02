require "rails_helper"

RSpec.describe "Jobs", type: :request do
  include ActiveJob::TestHelper

  let(:landlord) { create(:landlord) }
  let!(:property) { create(:property, landlord: landlord, city: "Austin", state: "TX") }
  let!(:unit) { create(:unit, property: property) }

  after { clear_enqueued_jobs }

  describe "landlord flow" do
    before { sign_in landlord }

    it "creates a draft job with trades and a photo" do
      photo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.png"), "image/png")

      expect {
        post jobs_path, params: { job: {
          title: "Fix roof", description: "Leaking", property_id: property.id,
          proposal_deadline: (Date.current + 10).to_s, trades: [ "", "roofing" ], attachments: [ photo ]
        } }
      }.to change(Job, :count).by(1)

      job = Job.last
      expect(job.trades).to eq(%w[roofing])
      expect(job.attachments.count).to eq(1)
      expect(job).to be_status_draft
      expect(response).to redirect_to(walkthroughs_job_path(job))
    end

    it "rejects a property that is not theirs" do
      other = create(:property)
      post jobs_path, params: { job: { title: "x", property_id: other.id, trades: [ "roofing" ] } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Job.count).to eq(0)
    end

    it "creates walkthrough slots in the chosen timezone" do
      job = create(:job, property: property)
      date = (Date.current + 5).to_s

      post job_walkthrough_slots_path(job), params: {
        date: date, times: [ "09:00", "13:00" ], duration_minutes: 60,
        timezone: "Central Time (US & Canada)", walkthrough_required: "1", slot_capacity: 2
      }

      job.reload
      expect(job.walkthrough_slots.count).to eq(2)
      expect(job.walkthrough_slots.first.starts_at.in_time_zone("Central Time (US & Canada)").hour).to eq(9)
      expect(job).to be_walkthrough_required
      expect(job.slot_capacity).to eq(2)
    end

    it "leaves the walkthrough form ready to add another slot" do
      job = create(:job, property: property, timezone: "Central Time (US & Canada)")
      zone = ActiveSupport::TimeZone["Central Time (US & Canada)"]
      start = zone.local(2026, 11, 3, 9)
      create(:walkthrough_slot, job: job, starts_at: start, ends_at: start + 1.hour)

      get walkthroughs_job_path(job)

      expect(response.body).to include('value="2026-11-03"')
      expect(response.body).to match(/value="60"[^>]*selected|selected[^>]*value="60"/)
      expect(response.body).not_to match(/id="times_0900"[^>]*checked/)
    end

    it "refuses to publish an incomplete job" do
      job = create(:job, property: property, description: nil)
      post publish_job_path(job)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(job.reload).to be_status_draft
    end

    it "publishes a valid job and notifies matching contractors" do
      create(:contractor, trades: %w[roofing], service_state: "TX", notify_matching_jobs: true)
      job = create(:job, property: property)

      post publish_job_path(job)

      expect(response).to redirect_to(job_path(job))
      expect(job.reload).to be_status_open
    end

    it "compares proposals and awards one" do
      job = create(:job, :open, property: property)
      cheap = create(:proposal, job: job, amount_cents: 100_000)
      create(:proposal, job: job, amount_cents: 300_000)

      get job_proposals_path(job)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$1,000")

      expect { post award_job_proposal_path(job, cheap) }.to change(WorkOrder, :count).by(1)
      expect(job.reload).to be_status_awarded
      expect(response).to redirect_to(work_order_path(WorkOrder.last))
    end

    it "does not show another landlord's job" do
      other_job = create(:job, :open)
      get job_path(other_job)
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "access" do
    it "keeps contractors away from landlord job management" do
      sign_in create(:contractor)
      get jobs_path
      expect(response).to redirect_to(root_path).or have_http_status(:forbidden)
    end
  end
end
