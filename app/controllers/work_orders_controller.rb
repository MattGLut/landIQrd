class WorkOrdersController < ApplicationController
  before_action :set_work_order, only: %i[show edit update destroy]
  before_action :load_units, only: %i[new create]

  def index
    authorize WorkOrder
    @work_orders = policy_scope(WorkOrder).includes(unit: :property).order(created_at: :desc)
  end

  def show
    authorize @work_order
    @contractors = User.contractor.order(:last_name, :first_name) if policy(@work_order).assign?
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
    if @work_order.update(update_params)
      redirect_to @work_order, notice: "Work order updated."
    else
      render :edit, status: :unprocessable_entity
    end
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
    params.require(:work_order).permit(:title, :description, :priority, :unit_id, :lease_id, photos: [])
  end

  def update_params
    params.require(:work_order).permit(:title, :description, :priority, :status, :lease_id, photos: [])
  end
end
