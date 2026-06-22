require "rails_helper"

RSpec.describe WorkOrders::Closer do
  let(:tenant) { create(:tenant) }
  let(:work_order) { create(:work_order, created_by: tenant, status: :open) }

  it "closes an active work order with a reason" do
    described_class.call(work_order, user: tenant, closure_reason: "No longer needed")

    work_order.reload
    expect(work_order).to be_status_cancelled
    expect(work_order.closure_reason).to eq("No longer needed")
    expect(work_order.closed_by).to eq(tenant)
    expect(work_order.work_order_events.last.action).to eq("closed")
  end

  it "requires a closure reason" do
    expect {
      described_class.call(work_order, user: tenant, closure_reason: "")
    }.to raise_error(WorkOrders::Closer::Error, "Closure reason is required")
  end
end
