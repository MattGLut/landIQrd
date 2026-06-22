module ApplicationHelper
  def nav_link(label, path)
    active = current_page?(path)
    classes = active ? "text-indigo-600 font-medium" : "text-gray-600 hover:text-gray-900"
    link_to label, path, class: "text-sm #{classes}"
  end

  def status_badge(text, color)
    palette = {
      gray: "bg-gray-100 text-gray-700",
      green: "bg-green-100 text-green-700",
      yellow: "bg-yellow-100 text-yellow-800",
      red: "bg-red-100 text-red-700",
      blue: "bg-blue-100 text-blue-700",
      indigo: "bg-indigo-100 text-indigo-700"
    }
    tag.span text, class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{palette.fetch(color, palette[:gray])}"
  end
end
