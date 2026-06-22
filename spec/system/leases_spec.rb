require "rails_helper"

RSpec.describe "Leases" do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant, first_name: "Toni", last_name: "Tenant") }
  let(:property) { create(:property, landlord: landlord, name: "Maple Court") }
  let(:unit) { create(:unit, property: property, label: "Apt 1A") }

  before do
    tenant
    create(
      :lease,
      unit: create(:unit, property: property),
      tenant: tenant,
      status: :ended,
      start_date: 2.years.ago.to_date,
      end_date: 1.year.ago.to_date
    )
    sign_in_and_visit(landlord, unit_path(unit))
  end

  it "creates a lease from the unit page" do
    click_link "New lease"

    select tenant.full_name, from: "Tenant"
    fill_in "Start date", with: Date.current
    fill_in "End date", with: 1.year.from_now.to_date
    fill_in "Monthly rent", with: "1500"
    fill_in "Security deposit", with: "1500"
    click_button "Save"

    expect(page).to have_content("Lease created.")
    expect(page).to have_content("Status")
    expect(page).to have_content("Tenant")
    expect(page).to have_content("Monthly rent")
    expect(page).to have_content("Toni Tenant")
  end

  it "starts a conversation from the lease page" do
    lease = create(:lease, unit: unit, tenant: tenant)

    visit lease_path(lease)
    click_button "Message tenant"

    expect(page).to have_content("Direct message")
    expect(page).to have_content(tenant.full_name)
  end

  it "shows lease details and message tenant action" do
    lease = create(:lease, unit: unit, tenant: tenant)

    visit lease_path(lease)

    expect(page).to have_content("Term")
    expect(page).to have_content("Deposit")
    expect(page).to have_content("No documents attached.")
    expect(page).to have_button("Message tenant")
  end

  it "edits and deletes a lease" do
    lease = create(:lease, unit: unit, tenant: tenant, rent_amount: 1500)

    visit lease_path(lease)
    click_link "Edit"
    fill_in "Monthly rent", with: "1600"
    click_button "Save"

    expect(page).to have_content("Lease updated.")

    click_button "Delete"

    expect(page).to have_content("Lease deleted.")
    expect(page).to have_content("Apt 1A")
  end
end
