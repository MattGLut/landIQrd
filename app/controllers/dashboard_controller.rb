class DashboardController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @properties_count = 0
    @open_work_orders_count = 0
    @assigned_work_orders_count = 0
    @conversations_count = 0
    @unread_conversations_count = 0
    @users_count = 0
    @work_orders_count = 0
    @leases = nil
    @expiring_leases = []
    @expiring_soon_lease = nil
    @recent_properties = []
    @recent_open_work_orders = []
    @recent_conversations = []
    @tenants_count = 0
    @recent_tenant_leases = []

    @conversations_count = current_user.conversations.count unless current_user.admin?
    @unread_conversations_count = helpers.unread_conversations_count(current_user) unless current_user.admin?

    case current_user.role.to_sym
    when :landlord
      load_landlord_dashboard
    when :tenant
      @leases = current_user.leases.includes(unit: :property)
      @open_work_orders_count = WorkOrder.for_tenant(current_user).active.count
      @expiring_soon_lease = current_user.leases.active.expiring_within(60).order(:end_date).first
    when :contractor
      @assigned_work_orders_count = current_user.assigned_work_orders.merge(WorkOrder.active).count
    when :admin
      @users_count = User.count
      @properties_count = Property.count
      @work_orders_count = WorkOrder.count
    end
  end

  private

  def load_landlord_dashboard
    @properties_count = current_user.properties.count
    @recent_properties = current_user.properties.includes(:units).order(:name).limit(6)

    open_work_orders = WorkOrder.for_landlord(current_user).active
                                  .includes(:created_by, unit: :property)
                                  .order(updated_at: :desc)
    @open_work_orders_count = open_work_orders.count
    @recent_open_work_orders = open_work_orders.limit(6)

    conversations = policy_scope(Conversation)
                      .includes(:participants, :messages, :conversation_participants, :work_order)
                      .order(updated_at: :desc)
    @recent_conversations = conversations.limit(6)

    @expiring_leases = Lease.joins(unit: :property)
                            .where(properties: { landlord_id: current_user.id })
                            .expiring_within(90)
                            .includes(:tenant, unit: :property)
                            .order(:end_date)
                            .limit(6)

    active_tenant_leases = Lease.joins(:tenant, unit: :property)
                                .where(properties: { landlord_id: current_user.id })
                                .active
                                .includes(:tenant, unit: :property)
                                .order("users.last_name ASC, users.first_name ASC, leases.start_date DESC")
    @tenants_count = active_tenant_leases.distinct.count(:tenant_id)
    @recent_tenant_leases = active_tenant_leases.to_a.uniq(&:tenant_id).first(6)
  end
end
