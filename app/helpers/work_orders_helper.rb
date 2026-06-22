module WorkOrdersHelper
  STATUS_PILL_COLORS = {
    blue: "border-blue-500/40 bg-blue-500/15 text-blue-300",
    yellow: "border-yellow-500/40 bg-yellow-500/15 text-yellow-300",
    indigo: "border-purple-500/40 bg-purple-500/15 text-purple-300",
    gray: "border-border-default bg-elevated text-muted hover:bg-surface",
    green: "border-accent/40 bg-accent/15 text-accent",
    red: "border-danger/40 bg-danger/15 text-danger"
  }.freeze

  def work_order_status_label(status, viewer: current_user, creator: nil)
    if status.to_s == "cancelled" && viewer&.tenant? && creator&.id == viewer.id
      "Closed"
    else
      status.to_s.titleize.gsub("_", " ")
    end
  end

  def work_order_status_options(work_order, policy)
    if policy.change_status?
      work_order.aasm.permitted_transitions
        .reject { |transition| transition[:event] == :close }
        .map do |transition|
          status = transition[:state].to_s
          [ work_order_status_label(status), status ]
        end
    elsif policy.close?
      [ [ "Closed", "cancelled" ] ]
    else
      []
    end
  end

  def work_order_status_manageable?(policy)
    policy.change_status? || policy.close?
  end

  def work_order_status_pill_classes(color)
    palette = STATUS_PILL_COLORS.fetch(color.to_sym, STATUS_PILL_COLORS[:gray])
    "inline-flex items-center gap-1 rounded-full border py-1 pl-3 pr-2 text-xs font-semibold shadow-sm transition-shadow hover:shadow focus:outline-none focus:ring-2 focus:ring-accent/30 #{palette}"
  end
end
