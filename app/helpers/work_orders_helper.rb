module WorkOrdersHelper
  STATUS_PILL_COLORS = {
    blue: "border-blue-200 bg-blue-50 text-blue-800 dark:border-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
    yellow: "border-amber-200 bg-amber-50 text-amber-800 dark:border-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
    indigo: "border-violet-200 bg-violet-50 text-violet-800 dark:border-violet-800 dark:bg-violet-900/30 dark:text-violet-300",
    gray: "border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600",
    green: "border-emerald-200 bg-emerald-50 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
    red: "border-rose-200 bg-rose-50 text-rose-800 dark:border-rose-800 dark:bg-rose-900/30 dark:text-rose-300"
  }.freeze

  def work_order_status_label(status, viewer: current_user, creator: nil)
    if status.to_s == "cancelled" && viewer&.tenant? && creator&.id == viewer.id
      "Closed"
    else
      status.to_s.titleize.gsub("_", " ")
    end
  end

  def work_order_status_options(work_order, policy)
    if work_order.status_completed? && policy.reopen?
      return [ [ "Reopen", "pending_management" ] ]
    end

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
    policy.change_status? || policy.close? || policy.reopen?
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
    "inline-flex items-center gap-1 rounded-full border py-1 pl-3 pr-2 text-xs font-semibold shadow-sm transition-shadow hover:shadow focus:outline-none focus:ring-2 focus:ring-brand-500/30 #{palette}"
  end

  def work_order_photo_thumbnail(photo)
    image_tag(
      work_order_photo_source(photo),
      class: "h-32 w-full object-cover",
      alt: photo.filename.to_s
    )
  end

  def work_order_photo_source(photo)
    return photo unless photo.variable?

    photo.variant(resize_to_limit: [ 300, 300 ]).processed
  rescue LoadError, StandardError
    photo
  end
end
