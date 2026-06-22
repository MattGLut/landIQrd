require "rails_helper"

RSpec.describe "Dashboard" do
  it "shows landlord stats and CTAs" do
    landlord = create(:landlord)
    property = create(:property, landlord: landlord)
    unit = create(:unit, property: property)
    tenant = create(:tenant)
    create(:lease, unit: unit, tenant: tenant)
    create(:work_order, unit: unit, created_by: tenant, status: :open)
    Conversation.direct_between!(tenant, landlord)

    sign_in_and_visit(landlord)

    expect(page).to have_content("Welcome back, #{landlord.first_name}")
    expect(page).to have_content("Properties")
    expect(page).to have_content("Open work orders")
    expect(page).to have_content("Conversations")
    expect(page).to have_link("Manage properties")
  end

  it "shows tenant leases and new work request CTA" do
    tenant = create(:tenant)
    landlord = create(:landlord)
    property = create(:property, landlord: landlord, name: "Oak Apartments")
    unit = create(:unit, property: property, label: "2B")
    create(:lease, unit: unit, tenant: tenant)

    sign_in_and_visit(tenant)

    expect(page).to have_content("Active leases")
    expect(page).to have_content("Your leases")
    expect(page).to have_content("Oak Apartments · 2B")
    expect(page).to have_link("New work request")
  end

  it "shows contractor assigned work count" do
    contractor = create(:contractor)
    landlord = create(:landlord)
    property = create(:property, landlord: landlord)
    unit = create(:unit, property: property)
    work_order = create(:work_order, unit: unit)
    create(:work_order_assignment, work_order: work_order, contractor: contractor)

    sign_in_and_visit(contractor)

    expect(page).to have_content("Assigned work orders")
    expect(page).to have_link("View assigned work")
  end

  it "shows admin console link and stats" do
    create(:landlord)
    create(:property)

    sign_in_and_visit(create(:admin))

    expect(page).to have_content("Users")
    expect(page).to have_content("Properties")
    expect(page).to have_link("Open admin console")
  end
end
