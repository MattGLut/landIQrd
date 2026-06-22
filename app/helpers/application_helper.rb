module ApplicationHelper
  def sidebar_link(path, label, icon: nil)
    active = if path == authenticated_root_path
      current_page?(path)
    else
      request.path == path.to_s || request.path.start_with?("#{path}/")
    end
    base = "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors"
    classes = if active
      "#{base} bg-accent/10 text-accent border-l-2 border-accent"
    else
      "#{base} text-muted hover:bg-elevated hover:text-primary border-l-2 border-transparent"
    end

    link_to path, class: classes do
      safe_join([ icon_svg(icon), tag.span(label) ].compact)
    end
  end

  def admin_tab_link(label, path)
    active = current_page?(path)
    classes = active ? "text-accent font-medium" : "text-muted hover:text-primary"
    link_to label, path, class: "text-sm #{classes}"
  end

  def status_badge(text, color)
    palette = {
      gray: "bg-elevated text-muted",
      green: "bg-accent/15 text-accent",
      yellow: "bg-yellow-500/15 text-yellow-400",
      red: "bg-danger/15 text-danger",
      blue: "bg-blue-500/15 text-blue-400",
      indigo: "bg-purple-500/15 text-purple-400"
    }
    tag.span text, class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{palette.fetch(color, palette[:gray])}"
  end

  def button_classes(variant = :primary, size: :md)
    base = "inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:ring-offset-base disabled:opacity-50"
    sizes = { sm: "px-3 py-1.5 text-xs", md: "px-4 py-2 text-sm", lg: "px-5 py-2.5 text-base" }
    variants = {
      primary: "bg-accent text-base hover:bg-accent-hover",
      secondary: "border border-border-default bg-surface text-primary hover:bg-elevated",
      danger: "border border-danger/30 bg-danger/10 text-danger hover:bg-danger/20",
      ghost: "text-muted hover:bg-elevated hover:text-primary"
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

  def property_breadcrumbs(*crumbs)
    tag.nav class: "mb-4 flex items-center gap-2 text-sm text-muted", "aria-label": "Breadcrumb" do
      safe_join(crumbs.each_with_index.map { |crumb, i|
        if i == crumbs.length - 1
          tag.span crumb[:label], class: "text-primary"
        else
          safe_join([
            link_to(crumb[:label], crumb[:path], class: "hover:text-accent"),
            tag.span("\u00b7", class: "text-border-default")
          ])
        end
      }.flatten)
    end
  end

  private

  def icon_svg(name)
    return unless name

    icons = {
      home: '<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>',
      building: '<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z"/>',
      wrench: '<path stroke-linecap="round" stroke-linejoin="round" d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z"/>',
      chat: '<path stroke-linecap="round" stroke-linejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z"/>',
      shield: '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"/>'
    }

    svg_path = icons.fetch(name.to_sym, icons[:home])
    tag.svg(class: "h-5 w-5 shrink-0", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", "stroke-width": "1.5") do
      svg_path.html_safe
    end
  end
end
