class DashboardController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @properties_count = 0
    @open_work_orders_count = 0
    @assigned_work_orders_count = 0
    @conversations_count = 0
    @users_count = 0
    @work_orders_count = 0
    @leases = nil

    @conversations_count = current_user.conversations.count unless current_user.admin?

    case current_user.role.to_sym
    when :landlord
      @properties_count = current_user.properties.count
      @open_work_orders_count = WorkOrder.for_landlord(current_user).active.count
    when :tenant
      @leases = current_user.leases.includes(unit: :property)
      @open_work_orders_count = WorkOrder.for_tenant(current_user).active.count
    when :contractor
      @assigned_work_orders_count = current_user.assigned_work_orders.merge(WorkOrder.active).count
    when :admin
      @users_count = User.count
      @properties_count = Property.count
      @work_orders_count = WorkOrder.count
    end
  end
end
