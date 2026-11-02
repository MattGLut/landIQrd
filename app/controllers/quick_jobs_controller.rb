class QuickJobsController < ApplicationController
  before_action :authorize_quick_job
  before_action :load_form_options

  def new
    contractor_id = params[:contractor_id].to_i
    contractor_id = nil unless @relationships.any? { |relationship| relationship.contractor_id == contractor_id }
    @quick_job = QuickJob.new(contractor_id: contractor_id)
  end

  def create
    @quick_job = QuickJob.new(quick_job_params)

    if @quick_job.invalid?
      render :new, status: :unprocessable_entity
      return
    end

    work_order = WorkOrders::QuickAssign.call(landlord: current_user, quick_job: @quick_job)
    redirect_to work_order, notice: "Job sent to #{work_order.contractors.first.display_name}. They need to accept it."
  rescue WorkOrders::QuickAssign::Error => e
    @quick_job.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  private

  def authorize_quick_job
    authorize :quick_job
  end

  def load_form_options
    @relationships = current_user.contractor_relationships.status_accepted.includes(:contractor).order(:id)
    @pending_count = current_user.contractor_relationships.status_pending.count
    @units = Unit.includes(:property).joins(:property)
                 .where(properties: { landlord_id: current_user.id })
                 .order("properties.name", :label)
  end

  def quick_job_params
    params.require(:quick_job).permit(
      :contractor_id, :unit_id, :title, :description, :category, :priority,
      :scheduled_at, :price, photos: []
    )
  end
end
