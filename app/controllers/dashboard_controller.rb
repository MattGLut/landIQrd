class DashboardController < ApplicationController
  skip_after_action :verify_authorized

  def show
    return redirect_to admin_dashboard_path if current_user.admin?

    @properties_count = 0
    @open_work_orders_count = 0
    @assigned_work_orders_count = 0
    @conversations_count = 0
    @unread_conversations_count = 0
    @users_count = 0
    @work_orders_count = 0
    @leases_count = 0
    @expiring_leases = []
    @recent_leases = []
    @active_work_order_counts_by_unit_id = {}
    @recent_properties = []
    @recent_open_work_orders = []
    @recent_assigned_work_orders = []
    @recent_conversations = []
    @tenants_count = 0
    @recent_tenant_leases = []

    @conversations_count = current_user.conversations.count
    @unread_conversations_count = helpers.unread_conversations_count(current_user)

    case current_user.role.to_sym
    when :landlord
      load_landlord_dashboard
    when :tenant
      load_tenant_dashboard
    when :contractor
      load_contractor_dashboard
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

  def load_tenant_dashboard
    active_leases = current_user.leases.active.includes(unit: :property).order(start_date: :desc)
    @leases_count = active_leases.count
    @recent_leases = active_leases.limit(6)
    @active_work_order_counts_by_unit_id = WorkOrder.active
                                                    .where(unit_id: @recent_leases.map(&:unit_id))
                                                    .group(:unit_id)
                                                    .count

    open_work_orders = WorkOrder.for_tenant(current_user).active
                                .includes(:created_by, unit: :property)
                                .order(updated_at: :desc)
    @open_work_orders_count = open_work_orders.count
    @recent_open_work_orders = open_work_orders.limit(6)

    conversations = policy_scope(Conversation)
                      .includes(:participants, :messages, :conversation_participants, :work_order)
                      .order(updated_at: :desc)
    @recent_conversations = conversations.limit(6)
  end

  def load_contractor_dashboard
    active_assigned = current_user.assigned_work_orders
                                  .merge(WorkOrder.active)
                                  .includes(:created_by, unit: :property)
                                  .order(updated_at: :desc)
    @assigned_work_orders_count = active_assigned.count
    @recent_assigned_work_orders = active_assigned.limit(6)

    conversations = policy_scope(Conversation)
                      .includes(:participants, :messages, :conversation_participants, :work_order)
                      .order(updated_at: :desc)
    @recent_conversations = conversations.limit(6)
  end
end
