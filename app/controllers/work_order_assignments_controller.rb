class WorkOrderAssignmentsController < ApplicationController
  before_action :set_work_order

  def create
    @assignment = @work_order.work_order_assignments.new(create_params)
    authorize @assignment
    if @assignment.save
      redirect_to @work_order, notice: "Contractor assigned."
    else
      redirect_to @work_order, alert: @assignment.errors.full_messages.to_sentence
    end
  end

  def update
    @assignment = @work_order.work_order_assignments.find(params[:id])
    authorize @assignment
    if @assignment.update(update_params)
      redirect_to @work_order, notice: "Assignment updated."
    else
      redirect_to @work_order, alert: @assignment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @assignment = @work_order.work_order_assignments.find(params[:id])
    authorize @assignment
    @assignment.destroy
    redirect_to @work_order, notice: "Assignment removed."
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:work_order_id])
  end

  def create_params
    params.require(:work_order_assignment).permit(:contractor_id, :scheduled_at)
  end

  def update_params
    params.require(:work_order_assignment).permit(:status, :scheduled_at)
  end
end
