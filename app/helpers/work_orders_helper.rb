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
      options = work_order.aasm.permitted_transitions
        .reject { |transition| transition[:event] == :close }
        .map do |transition|
          status = transition[:state].to_s
          [ work_order_status_label(status), status ]
        end

      if work_order.active? && policy.close?
        options << [ "Closed", "closed" ]
      end

      options
    elsif policy.close?
      [ [ "Closed", "cancelled" ] ]
    else
      []
    end
  end

  def work_order_status_manageable?(policy)
    policy.change_status? || policy.close?
  end

  def work_order_status_option_attrs(value, policy)
    case value.to_s
    when "closed"
      {
        dialog_title: "Close work order",
        dialog_description: "Tell us why you're closing this work order.",
        reason_required: true,
        submit_mode: "close"
      }
    when "cancelled"
      if policy.close? && !policy.change_status?
        {
          dialog_title: "Close request",
          dialog_description: "Tell us why you're closing this request.",
          reason_required: true,
          submit_mode: "close"
        }
      else
        {
          dialog_title: "Cancel work order",
          dialog_description: "Optionally share why this work order is being cancelled.",
          reason_required: false,
          submit_mode: "patch-cancel"
        }
      end
    else
      {}
    end
  end

  def work_order_status_pill_classes(color)
    palette = STATUS_PILL_COLORS.fetch(color.to_sym, STATUS_PILL_COLORS[:gray])
    "inline-flex items-center gap-1 rounded-full border py-1 pl-3 pr-2 text-xs font-semibold shadow-sm transition-shadow hover:shadow focus:outline-none focus:ring-2 focus:ring-accent/30 #{palette}"
  end
end
