require "rails_helper"

RSpec.describe LeasesHelper, type: :helper do
  describe "#lease_dashboard_tags" do
    it "returns expiring soon and work order tags when applicable" do
      lease = build(:lease, status: :active, end_date: 2.weeks.from_now.to_date, unit: build(:unit, id: 42))

      tags = helper.lease_dashboard_tags(lease, work_order_counts: { 42 => 1 })

      expect(tags).to eq([
        { label: "Expiring soon", color: :yellow },
        { label: "Work order", color: :blue }
      ])
    end

    it "returns no tags when nothing applies" do
      lease = build(:lease, status: :active, end_date: 6.months.from_now.to_date, unit: build(:unit, id: 7))

      expect(helper.lease_dashboard_tags(lease, work_order_counts: {})).to eq([])
    end
  end
end
