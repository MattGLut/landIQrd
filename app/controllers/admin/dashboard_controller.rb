module Admin
  class DashboardController < BaseController
    def show
      @users_count = User.count
      @properties_count = Property.count
      @work_orders_count = WorkOrder.count
      @open_work_orders_count = WorkOrder.active.count
      @conversations_count = Conversation.count
      @users_by_role = User.group(:role).count
      @recent_work_orders = WorkOrder.includes(unit: :property).order(created_at: :desc).limit(5)
    end
  end
end
