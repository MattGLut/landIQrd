module LeasesHelper
  def lease_dashboard_tags(lease, work_order_counts: {})
    tags = []

    if lease.expiring_soon?
      tags << { label: "Expiring soon", color: :yellow }
    end

    if (work_order_counts[lease.unit_id] || 0).positive?
      tags << { label: "Work order", color: :blue }
    end

    tags
  end
end
