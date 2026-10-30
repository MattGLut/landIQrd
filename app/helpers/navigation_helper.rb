# frozen_string_literal: true

# Role-aware sidebar navigation and inline icons (outline set, 24x24).
module NavigationHelper
  # `match` is the path used for active-state detection when `path` carries a query string.
  NavItem = Struct.new(:label, :path, :icon, :exclude, :badge, :match, keyword_init: true)

  ICON_PATHS = {
    dashboard: "M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z",
    properties: "M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21",
    work_orders: "M21.75 6.75a4.5 4.5 0 01-4.884 4.484c-1.076-.091-2.264.071-2.95.904l-7.152 8.684a2.548 2.548 0 11-3.586-3.586l8.684-7.152c.833-.686.995-1.874.904-2.95a4.5 4.5 0 016.336-4.486l-3.276 3.276a3.004 3.004 0 002.25 2.25l3.276-3.276c.256.565.398 1.192.398 1.852z",
    contractors: "M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z",
    messages: "M20.25 8.511c.884.284 1.5 1.128 1.5 2.097v4.286c0 1.136-.847 2.1-1.98 2.193-.34.027-.68.052-1.02.072v3.091l-3-3c-1.354 0-2.694-.055-4.02-.163a2.115 2.115 0 01-.825-.242m9.345-8.334a2.126 2.126 0 00-.476-.095 48.64 48.64 0 00-8.048 0c-1.131.094-1.976 1.057-1.976 2.192v4.286c0 .837.46 1.58 1.155 1.951m9.345-8.334V6.637c0-1.621-1.152-3.026-2.76-3.235A48.455 48.455 0 0011.25 3c-2.115 0-4.198.137-6.24.402-1.608.209-2.76 1.614-2.76 3.235v6.226c0 1.621 1.152 3.026 2.76 3.235.577.075 1.157.14 1.74.194V21l4.155-4.155",
    calendar: "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5",
    document: "M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z",
    search: "M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z",
    portfolio: "M20.25 14.15v4.25c0 1.094-.787 2.036-1.872 2.18-2.087.277-4.216.42-6.378.42s-4.291-.143-6.378-.42c-1.085-.144-1.872-1.086-1.872-2.18v-4.25m16.5 0a2.18 2.18 0 00.75-1.661V8.706c0-1.081-.768-2.015-1.837-2.175a48.114 48.114 0 00-3.413-.387m4.5 8.006c-.194.165-.42.295-.673.38A23.978 23.978 0 0112 15.75c-2.648 0-5.195-.429-7.577-1.22a2.016 2.016 0 01-.673-.38m0 0A2.18 2.18 0 013 12.489V8.706c0-1.081.768-2.015 1.837-2.175a48.111 48.111 0 013.413-.387m7.5 0V5.25A2.25 2.25 0 0013.5 3h-3a2.25 2.25 0 00-2.25 2.25v.894m7.5 0a48.667 48.667 0 00-7.5 0M12 12.75h.008v.008H12v-.008z",
    check: "M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
    shield: "M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z",
    bell: "M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0",
    profile: "M17.982 18.725A7.488 7.488 0 0012 15.75a7.488 7.488 0 00-5.982 2.975m11.963 0a9 9 0 10-11.963 0m11.963 0A8.966 8.966 0 0112 21a8.966 8.966 0 01-5.982-2.275M15 9.75a3 3 0 11-6 0 3 3 0 016 0z",
    menu: "M3.75 6.75h16.5M3.75 12h16.5M3.75 17.25h16.5",
    close: "M6 18L18 6M6 6l12 12",
    upload: "M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z",
    clip: "M18.375 12.739l-7.693 7.693a4.5 4.5 0 01-6.364-6.364l10.94-10.94A3 3 0 1119.5 7.372L8.552 18.32m.009-.01l-.01.01m5.699-9.941l-7.81 7.81a1.5 1.5 0 002.112 2.13",
    pin: "M15 10.5a3 3 0 11-6 0 3 3 0 016 0z M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z",
    clock: "M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z",
    plus: "M12 4.5v15m7.5-7.5h-15",
    arrow_right: "M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3",
    arrow_left: "M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
  }.freeze

  def icon_tag(name, classes: "h-5 w-5")
    path = ICON_PATHS.fetch(name.to_sym)
    tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor", "aria-hidden": "true") do
      tag.path(d: path, "stroke-linecap": "round", "stroke-linejoin": "round")
    end
  end

  def sidebar_items_for(user)
    return [] unless user

    items = [ NavItem.new(label: "Dashboard", path: dashboard_path_for(user), icon: :dashboard) ]

    case user.role
    when "landlord"
      items << NavItem.new(label: "Properties", path: properties_path, icon: :properties)
      items << NavItem.new(label: "Work Orders", path: work_orders_path, icon: :work_orders, exclude: schedule_work_orders_path)
      items << NavItem.new(label: "Proposals", path: jobs_path, icon: :document)
      items << NavItem.new(label: "Schedule", path: schedule_work_orders_path, icon: :calendar)
      items << NavItem.new(label: "Contractors", path: contractors_path, icon: :contractors)
    when "contractor"
      items << NavItem.new(label: "My trades", path: contractor_trades_path, icon: :check)
      items << NavItem.new(label: "Find work", path: contractor_available_jobs_path, icon: :search)
      items << NavItem.new(label: "Walkthroughs", path: contractor_walkthrough_bookings_path, icon: :calendar)
      items << NavItem.new(label: "Proposals", path: contractor_proposals_path, icon: :document)
      items << NavItem.new(label: work_orders_nav_label, path: work_orders_path(status: "active"), match: work_orders_path, icon: :work_orders, exclude: schedule_work_orders_path)
      items << NavItem.new(label: "Schedule", path: schedule_work_orders_path, icon: :calendar)
      items << NavItem.new(label: "Portfolio", path: contractor_portfolio_items_path, icon: :portfolio)
      items << NavItem.new(label: "Company profile", path: edit_contractor_business_profile_path, icon: :profile)
    when "tenant"
      items << NavItem.new(label: work_orders_nav_label, path: work_orders_path, icon: :work_orders)
    when "admin"
      items << NavItem.new(label: "Users", path: admin_users_path, icon: :profile)
      items << NavItem.new(label: "Properties", path: properties_path, icon: :properties)
      items << NavItem.new(label: "Work Orders", path: work_orders_path, icon: :work_orders, exclude: schedule_work_orders_path)
      items << NavItem.new(label: "Contractors", path: contractors_path, icon: :contractors)
    end

    items << NavItem.new(label: "Messages", path: conversations_path, icon: :messages, badge: unread_conversations_count(user))
    items
  end

  # Header breadcrumb: the active sidebar section, plus the page title when it
  # differs (e.g. ["Proposals", "Roof repair"]).
  def header_crumbs(user)
    section = sidebar_items_for(user).find do |item|
      nav_link_active?(item.match || item.path, exclude_paths: Array(item.exclude))
    end
    title = content_for(:title).to_s.strip
    title = "" if section&.path == dashboard_path_for(user)

    [ section&.label, title.presence ].compact.uniq
  end

  def dashboard_path_for(user)
    user.admin? ? admin_dashboard_path : authenticated_root_path
  end

  def sidebar_link(item)
    active = nav_link_active?(item.match || item.path, exclude_paths: Array(item.exclude))
    link_to item.path, class: "sidebar-link", "aria-current": (active ? "page" : nil) do
      safe_join([
        icon_tag(item.icon),
        tag.span(item.label, class: "flex-1"),
        sidebar_badge(item.badge)
      ].compact)
    end
  end

  def sidebar_badge(count)
    return if count.to_i.zero?

    tag.span count, class: "inline-flex min-w-[1.25rem] items-center justify-center rounded-full bg-brand-400 px-1.5 py-0.5 text-xs font-semibold text-navy-900"
  end
end
