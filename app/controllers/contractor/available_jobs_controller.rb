module Contractor
  # "Find work": open jobs that match the contractor's trades.
  class AvailableJobsController < BaseController
    def index
      authorize Job, :browse?
      @trade = params[:trade].presence_in(WorkOrderCategory::MARKETPLACE_TRADES)
      jobs = policy_scope(Job).accepting_proposals
      jobs = jobs.matching_trades([ @trade ]) if @trade
      @jobs = jobs.includes(:property, :walkthrough_slots, attachments_attachments: :blob).recent
      @proposed_job_ids = current_user.proposals.where(job_id: @jobs.map(&:id)).pluck(:job_id)
    end

    def show
      @job = policy_scope(Job).includes(:property, :walkthrough_slots).find(params[:id])
      authorize @job
      @booking = @job.booking_for(current_user)
      @proposal = @job.proposal_for(current_user)
      @slots = @job.walkthrough_slots.chronological
    end
  end
end
