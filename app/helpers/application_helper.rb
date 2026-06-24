module ApplicationHelper
  def nav_link_class(path, exclude_paths: [])
    active = nav_link_active?(path, exclude_paths:)
    if active
      "font-medium text-brand-600 dark:text-brand-400"
    else
      "text-[var(--color-text-secondary)] hover:text-brand-600 dark:hover:text-brand-400"
    end
  end

  def nav_link_active?(path, exclude_paths: [])
    excluded_paths = Array(exclude_paths)
    if path == authenticated_root_path
      current_page?(path)
    elsif request.path == path.to_s
      true
    elsif excluded_paths.any? { |excluded| request.path == excluded.to_s || request.path.start_with?("#{excluded}/") }
      false
    else
      request.path.start_with?("#{path}/")
    end
  end

  def admin_tab_link(label, path)
    active = current_page?(path)
    classes = active ? "text-brand-600 dark:text-brand-400 font-medium" : "text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-slate-100"
    link_to label, path, class: "text-sm #{classes}"
  end

  def status_badge(text, color)
    palette = {
      gray: "bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300",
      green: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
      yellow: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
      red: "bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-300",
      blue: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
      indigo: "bg-violet-100 text-violet-800 dark:bg-violet-900/30 dark:text-violet-300"
    }
    tag.span text, class: "inline-flex shrink-0 whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium #{palette.fetch(color, palette[:gray])}"
  end

  def button_classes(variant = :primary, size: :md)
    base = "inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 disabled:opacity-50"
    sizes = { sm: "px-3 py-1.5 text-xs", md: "px-4 py-2 text-sm", lg: "px-5 py-2.5 text-base" }
    variants = {
      primary: "bg-brand-600 text-white hover:bg-brand-700",
      secondary: "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700",
      danger: "border border-rose-200 bg-rose-50 text-rose-700 hover:bg-rose-100 dark:border-rose-800 dark:bg-rose-900/30 dark:text-rose-300 dark:hover:bg-rose-900/50",
      danger_link: "text-rose-600 hover:text-rose-700 dark:text-rose-400 dark:hover:text-rose-300",
      ghost: "text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-700 dark:hover:text-slate-100"
    }
    "#{base} #{sizes.fetch(size)} #{variants.fetch(variant)}"
  end

  def work_orders_nav_label
    case current_user&.role
    when "tenant" then "My Requests"
    when "contractor" then "Assigned Work"
    else "Work Orders"
    end
  end

  def unread_conversations_count(user)
    return 0 unless user

    user.conversations.includes(:messages, :conversation_participants).count do |conversation|
      conversation.unread_for?(user)
    end
  end

  def unread_badge(count)
    return if count.to_i.zero?

    tag.span count, class: "ml-1 inline-flex min-w-[1.25rem] items-center justify-center rounded-full bg-brand-600 px-1.5 py-0.5 text-xs font-medium text-white"
  end

  def property_breadcrumbs(*crumbs)
    tag.nav class: "mb-4 flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400", "aria-label": "Breadcrumb" do
      safe_join(crumbs.each_with_index.map { |crumb, i|
        if i == crumbs.length - 1
          tag.span crumb[:label], class: "text-slate-900 dark:text-slate-100"
        else
          safe_join([
            link_to(crumb[:label], crumb[:path], class: "hover:text-brand-600 dark:hover:text-brand-400"),
            tag.span("\u00b7", class: "text-slate-300 dark:text-slate-600")
          ])
        end
      }.flatten)
    end
  end

  def nav_link_classes(active:)
    base = "block rounded-lg px-3 py-2 text-sm"
    if active
      "#{base} bg-brand-50 font-medium text-brand-700 dark:bg-brand-900/30 dark:text-brand-400"
    else
      "#{base} text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-700 dark:hover:text-slate-100"
    end
  end

  AVATAR_SIZE_CLASSES = {
    sm: "h-8 w-8 text-xs leading-none",
    md: "h-9 w-9 text-sm leading-none",
    lg: "h-12 w-12 text-base leading-none"
  }.freeze

  AVATAR_PALETTE = %w[
    bg-brand-100
    bg-emerald-100
    bg-amber-100
    bg-rose-100
    bg-sky-100
    bg-violet-100
    bg-indigo-100
  ].freeze

  AVATAR_INK = %w[
    text-brand-700
    text-emerald-700
    text-amber-700
    text-rose-700
    text-sky-700
    text-violet-700
    text-indigo-700
  ].freeze

  def avatar_initials_circle_classes(user, size = nil)
    size_key = size&.to_sym || :sm
    idx = (user.id || user.email.to_s.sum) % AVATAR_PALETTE.length
    [
      AVATAR_SIZE_CLASSES.fetch(size_key, AVATAR_SIZE_CLASSES[:sm]),
      AVATAR_PALETTE[idx],
      AVATAR_INK[idx],
      "grid shrink-0 place-items-center rounded-full font-semibold tabular-nums " \
      "ring-1 ring-slate-200 dark:ring-slate-700 select-none"
    ].join(" ")
  end
end
