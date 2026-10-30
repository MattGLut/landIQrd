class JobsController < ApplicationController
  before_action :set_job, only: %i[show edit update destroy walkthroughs review publish close]
  before_action :load_properties, only: %i[new create edit update]

  def index
    authorize Job
    @jobs = policy_scope(Job).includes(:property, :proposals).recent
    @status_filter = params[:status].presence_in(Job.statuses.keys)
    @jobs = @jobs.where(status: @status_filter) if @status_filter
  end

  def show
    authorize @job, :manage?
    @proposals = @job.proposals.active.includes(:contractor)
    @bookings = booked_appointments
  end

  def new
    @job = Job.new(created_by: current_user, property: @properties.first)
    @job.trades = Array(params[:trades])
    authorize @job
    @matches = matches_for(@job)
  end

  def create
    @job = Job.new(job_params)
    @job.created_by = current_user
    @job.property = @properties.find_by(id: job_params[:property_id])
    authorize @job

    if @job.property.nil?
      @job.errors.add(:property, "must be one of your properties")
      @matches = matches_for(@job)
      render :new, status: :unprocessable_entity
    elsif @job.save
      redirect_to walkthroughs_job_path(@job), notice: "Job saved. Set up walkthroughs next."
    else
      @matches = matches_for(@job)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @job, :update?
    @matches = matches_for(@job)
  end

  def update
    authorize @job

    if @job.update(job_params.except(:property_id))
      redirect_to walkthroughs_job_path(@job), notice: "Job updated."
    else
      @matches = matches_for(@job)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job
    @job.destroy
    redirect_to jobs_path, notice: "Draft deleted."
  end

  # Step 2: walkthrough availability (also the "Walkthroughs" tab on a posted job).
  def walkthroughs
    authorize @job, :manage?
    @slots = @job.walkthrough_slots.includes(walkthrough_bookings: :contractor)
    @bookings = booked_appointments
  end

  # Step 3: review and post.
  def review
    authorize @job, :publish?
    @matches = matches_for(@job)
    @job.valid?(:publish)
  end

  def publish
    authorize @job

    if @job.valid?(:publish)
      @job.publish!
      Notifications::Deliver.matching_job_posted(@job, actor: current_user)
      redirect_to @job, notice: "Job posted. Matching contractors have been notified."
    else
      @matches = matches_for(@job)
      render :review, status: :unprocessable_entity
    end
  end

  def close
    authorize @job
    @job.close!
    redirect_to @job, notice: "Job closed."
  end

  # Turbo Frame: live "Matching contractors" panel while the form is edited.
  def matches
    authorize Job, :create?
    property = policy_scope(Property).find_by(id: params[:property_id])
    @matches = Jobs::MatchContractors.call(
      trades: Array(params[:trades]),
      city: property&.city,
      state: property&.state,
      limit: 6
    )
    @trades = Array(params[:trades]).compact_blank
  end

  private

  def set_job
    @job = policy_scope(Job).includes(:property, :walkthrough_slots).find(params[:id])
  end

  def load_properties
    @properties = policy_scope(Property).order(:name)
  end

  def job_params
    params.require(:job).permit(
      :title, :description, :property_id, :proposal_deadline,
      trades: [], attachments: []
    )
  end

  def matches_for(job)
    Jobs::MatchContractors.call(
      trades: job.trades,
      city: job.property&.city,
      state: job.property&.state,
      limit: 6
    )
  end

  def booked_appointments
    @job.walkthrough_bookings.confirmed.includes(:contractor, :walkthrough_slot).order("walkthrough_slots.starts_at")
  end
end
