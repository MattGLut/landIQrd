module Contractor
  class ProposalsController < BaseController
    before_action :set_job, only: %i[new create]
    before_action :set_proposal, only: %i[show edit update withdraw]

    def index
      authorize Proposal
      @proposals = policy_scope(Proposal).includes(job: :property).order(created_at: :desc)
    end

    def show
      authorize @proposal
    end

    def new
      @proposal = Proposal.new(job: @job, contractor: current_user, earliest_start: Date.current + 7.days)
      authorize @proposal, :create?
    end

    def create
      @proposal = Proposal.new(proposal_params.merge(job: @job, contractor: current_user))
      authorize @proposal, :create?

      if @proposal.save
        Notifications::Deliver.proposal_received(@proposal, actor: current_user)
        redirect_to contractor_proposal_path(@proposal), notice: "Proposal submitted."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @proposal, :update?
      @job = @proposal.job
    end

    def update
      authorize @proposal
      @job = @proposal.job

      if @proposal.update(proposal_params)
        redirect_to contractor_proposal_path(@proposal), notice: "Proposal updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def withdraw
      authorize @proposal
      @proposal.withdraw!
      redirect_to contractor_proposals_path, notice: "Proposal withdrawn."
    end

    private

    def set_job
      @job = policy_scope(Job).find(params[:available_job_id])
    end

    def set_proposal
      @proposal = policy_scope(Proposal).includes(job: :property).find(params[:id])
    end

    def proposal_params
      params.require(:proposal).permit(
        :amount, :scope, :exclusions, :earliest_start, :estimated_duration_days, attachments: []
      )
    end
  end
end
