class ProposalsController < ApplicationController
  before_action :set_job

  def index
    authorize @job, :view_proposals?
    @sort = params[:sort].presence_in(%w[price newest]) || "price"
    scope = policy_scope(Proposal).where(job_id: @job.id).active.includes(:contractor, attachments_attachments: :blob)
    @proposals = @sort == "newest" ? scope.order(created_at: :desc) : scope.cheapest_first
    @lowest_cents = @proposals.map(&:amount_cents).min
  end

  def show
    @proposal = policy_scope(Proposal).where(job_id: @job.id).find(params[:id])
    authorize @proposal
    @booking = @job.booking_for(@proposal.contractor)
  end

  def award
    @proposal = policy_scope(Proposal).where(job_id: @job.id).find(params[:id])
    authorize @proposal

    work_order = Jobs::Award.call(job: @job, proposal: @proposal, awarded_by: current_user)
    redirect_to work_order, notice: "Proposal awarded. The work order has been created."
  rescue Jobs::Award::Error, ActiveRecord::RecordInvalid => e
    redirect_to job_proposals_path(@job), alert: e.message
  end

  private

  def set_job
    @job = policy_scope(Job).find(params[:job_id])
  end
end
