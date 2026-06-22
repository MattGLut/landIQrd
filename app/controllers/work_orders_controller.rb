class WorkOrdersController < ApplicationController
  before_action :set_work_order, only: %i[show edit update destroy close]
  before_action :load_units, only: %i[new create]

  def index
    authorize WorkOrder
    @work_orders = filtered_work_orders
    @status_filter = params[:status]
  end

  def schedule
    authorize WorkOrder, :schedule?
    @assignments = scheduled_assignments
  end

  def show
    authorize @work_order
    @contractors = User.contractor.order(:last_name, :first_name) if policy(@work_order).assign?
    @events = @work_order.work_order_events.includes(:user).chronological
  end

  def new
    @work_order = WorkOrder.new
    authorize @work_order
  end

  def create
    @work_order = WorkOrder.new(create_params)
    @work_order.created_by = current_user
    @work_order.status = :open
    @work_order.unit = @units.find_by(id: create_params[:unit_id])
    authorize @work_order

    if @work_order.unit.nil?
      @work_order.errors.add(:unit_id, "is not available to you")
      render :new, status: :unprocessable_entity
    elsif @work_order.save
      Notifications::Deliver.work_order_created(@work_order, actor: current_user)
      redirect_to @work_order, notice: "Work request submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @work_order
  end

  def update
    authorize @work_order

    if update_status_param.present? && policy(@work_order).change_status?
      apply_status_transition
    elsif policy(@work_order).edit_details?
      apply_detail_update
    else
      redirect_to @work_order, alert: "You are not allowed to update this work order."
    end
  end

  def close
    authorize @work_order, :close?
    WorkOrders::Closer.call(@work_order, user: current_user, closure_reason: params[:closure_reason])
    redirect_to @work_order, notice: "Work request closed."
  rescue WorkOrders::Closer::Error => e
    redirect_to @work_order, alert: e.message
  end

  def destroy
    authorize @work_order
    @work_order.destroy
    redirect_to work_orders_path, notice: "Work order deleted."
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def load_units
    @units =
      if current_user.admin?
        Unit.includes(:property).all
      elsif current_user.landlord?
        Unit.includes(:property).joins(:property).where(properties: { landlord_id: current_user.id })
      else
        Unit.includes(:property).joins(:leases).where(leases: { tenant_id: current_user.id }).distinct
      end
  end

  def create_params
    params.require(:work_order).permit(:title, :description, :priority, :category, :unit_id, :lease_id, photos: [])
  end

  def update_params
    params.require(:work_order).permit(:title, :description, :priority, :category, :status, :lease_id, photos: [])
  end

  def update_status_param
    update_params[:status]
  end

  def apply_status_transition
    WorkOrders::TransitionStatus.call(
      work_order: @work_order,
      to: update_status_param,
      user: current_user,
      closure_reason: params.dig(:work_order, :closure_reason)
    )
    redirect_to @work_order, notice: "Work order updated."
  rescue WorkOrders::TransitionStatus::InvalidTransition => e
    redirect_to edit_work_order_path(@work_order), alert: e.message
  end

  def apply_detail_update
    tracked = @work_order.attributes.slice("title", "description", "priority", "category")
    if @work_order.update(update_params.except(:status))
      changes = tracked.each_with_object({}) do |(field, old_value), memo|
        new_value = @work_order.public_send(field)
        memo[field] = [ old_value, new_value ] if old_value != new_value
      end
      if changes.any?
        WorkOrders::RecordEvent.call(
          work_order: @work_order,
          user: current_user,
          action: "updated",
          metadata: { "changes" => changes }
        )
      end
      redirect_to @work_order, notice: "Work order updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def filtered_work_orders
    scope = policy_scope(WorkOrder).includes(unit: :property).order(created_at: :desc)
    case params[:status]
    when "active"
      scope.active
    when "completed"
      scope.where(status: :completed)
    when "cancelled"
      scope.where(status: :cancelled)
    else
      scope
    end
  end

  def scheduled_assignments
    scope = WorkOrderAssignment.includes(work_order: { unit: :property }, contractor: [])
                               .where.not(scheduled_at: nil)
                               .order(:scheduled_at)
    if current_user.contractor?
      scope.where(contractor_id: current_user.id)
    elsif current_user.landlord?
      scope.joins(work_order: { unit: :property }).where(properties: { landlord_id: current_user.id })
    else
      scope
    end
  end
end
