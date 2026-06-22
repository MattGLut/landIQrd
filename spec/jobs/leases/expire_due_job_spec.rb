require "rails_helper"

RSpec.describe Leases::ExpireDueJob do
  include ActiveJob::TestHelper

  after { clear_enqueued_jobs }

  it "ends active leases past their end date and notifies stakeholders" do
    landlord = create(:landlord)
    property = create(:property, landlord: landlord)
    unit = create(:unit, property: property)
    tenant = create(:tenant)
    lease = create(
      :lease,
      unit: unit,
      tenant: tenant,
      status: :active,
      start_date: 1.year.ago.to_date,
      end_date: 1.day.ago.to_date
    )

    expect {
      described_class.perform_now
    }.to change { lease.reload.status }.from("active").to("ended")
      .and have_enqueued_mail(NotificationMailer, :lease_expiring).exactly(2).times
  end

  it "leaves current leases alone" do
    lease = create(:lease, status: :active, end_date: 1.month.from_now.to_date)

    expect {
      described_class.perform_now
    }.not_to change { lease.reload.status }
  end
end
