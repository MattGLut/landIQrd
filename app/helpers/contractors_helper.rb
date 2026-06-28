module ContractorsHelper
  def contractor_website_link(user, **options)
    return if user.website_url.blank?

    link_to user.website_url, user.website_url,
            class: options[:class] || "text-sm text-brand-600 hover:text-brand-800 dark:text-brand-400 dark:hover:text-brand-300",
            target: "_blank", rel: "noopener noreferrer"
  end

  def portfolio_photo_thumbnail(photo, compact: false)
    image_tag(
      portfolio_photo_source(photo),
      class: compact ? "h-full w-full object-cover" : "h-32 w-full object-cover",
      alt: photo.filename.to_s
    )
  end

  def portfolio_photo_source(photo)
    return photo unless photo.variable?

    photo.variant(resize_to_limit: [ 300, 300 ]).processed
  rescue LoadError, StandardError
    photo
  end

  def contractor_match_badge(contractor, category)
    count = contractor.relevant_portfolio_items_for(category).count
    return if count.zero?

    label = count == 1 ? "1 relevant project" : "#{count} relevant projects"
    status_badge(label, :green)
  end

  def contractor_category_filter_options
    [ [ "All trades", nil ] ] + WorkOrder.all_category_options
  end
end
