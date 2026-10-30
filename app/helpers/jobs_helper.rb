module JobsHelper
  WALKTHROUGH_TIME_OPTIONS = %w[08:00 09:00 10:00 11:00 12:00 13:00 14:00 15:00 16:00 17:00].freeze
  WALKTHROUGH_DURATIONS = { "15 minutes" => 15, "30 minutes" => 30, "45 minutes" => 45, "1 hour" => 60, "2 hours" => 120 }.freeze

  def format_cents(cents)
    return "-" if cents.nil?

    number_to_currency(cents / 100.0, precision: (cents % 100).zero? ? 0 : 2)
  end

  def job_status_color(job)
    {
      "draft" => :gray,
      "open" => :green,
      "awarded" => :blue,
      "closed" => :red
    }.fetch(job.status, :gray)
  end

  def job_status_badge(job)
    status_badge job.status.titleize, job_status_color(job)
  end

  def proposal_status_color(proposal)
    {
      "submitted" => :blue,
      "awarded" => :green,
      "declined" => :gray,
      "withdrawn" => :red
    }.fetch(proposal.status, :gray)
  end

  def proposal_status_badge(proposal)
    status_badge proposal.status.titleize, proposal_status_color(proposal)
  end

  def trade_badges(trades)
    safe_join(trades.map { |trade| status_badge(WorkOrder.trade_label(trade), :indigo) }, " ")
  end

  def walkthrough_time_label(value)
    Time.zone.parse("2000-01-01 #{value}").strftime("%-l:%M %p")
  end

  def format_slot_range(slot)
    "#{slot.day_label}, #{slot.time_range_label}"
  end

  # First image attachment as a square thumbnail, or a neutral placeholder.
  def job_thumbnail(job, classes: "h-28 w-36")
    image = job.attachments.find(&:image?)
    if image
      image_tag image.variant(resize_to_fill: [ 360, 280 ]), class: "#{classes} shrink-0 rounded-lg object-cover", alt: job.title
    else
      tag.div(icon_tag(:work_orders, classes: "h-8 w-8"), class: "#{classes} grid shrink-0 place-items-center rounded-lg bg-slate-100 text-slate-400 dark:bg-slate-700/50")
    end
  end

  def match_badge_classes
    "inline-flex shrink-0 items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-300 dark:ring-emerald-800"
  end

  def trade_checkbox_label_classes
    "flex cursor-pointer items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 " \
      "has-[:checked]:border-brand-400 has-[:checked]:bg-brand-50 has-[:checked]:text-brand-800 " \
      "dark:border-slate-600 dark:bg-slate-800 dark:text-slate-200 " \
      "dark:has-[:checked]:border-brand-500 dark:has-[:checked]:bg-brand-900/30 dark:has-[:checked]:text-brand-200"
  end

  def tab_link_classes(active)
    base = "border-b-2 px-1 pb-3 text-sm font-medium transition-colors"
    if active
      "#{base} border-brand-500 text-brand-700 dark:text-brand-300"
    else
      "#{base} border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
    end
  end
end
