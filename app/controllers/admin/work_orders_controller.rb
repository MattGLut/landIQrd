module Admin
  class WorkOrdersController < BaseController
    def index
      @work_orders = WorkOrder.includes(unit: :property).order(created_at: :desc)
    end

    def show
      @work_order = WorkOrder.find(params[:id])
    end
  end
end
