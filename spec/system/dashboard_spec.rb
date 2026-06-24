require "rails_helper"

RSpec.describe "Dashboard" do
  it "shows landlord stats and CTAs" do
    landlord = create(:landlord)
    property = create(:property, landlord: landlord, name: "Maple Court")
    unit = create(:unit, property: property)
    tenant = create(:tenant)
    create(:lease, unit: unit, tenant: tenant)
    work_order = create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Leaky faucet")
    conversation = Conversation.direct_between!(tenant, landlord)
    conversation.messages.create!(author: tenant, body: "Can we schedule a visit?")

    sign_in_and_visit(landlord)

    expect(page).to have_content("Welcome back, #{landlord.first_name}")
    expect(page).to have_content("Properties")
    expect(page).to have_content("Open work orders")
    expect(page).to have_content("Tenants")
    expect(page).to have_content("Conversations")
    expect(page).to have_content("Maple Court")
    expect(page).to have_content(tenant.full_name)
    expect(page).to have_content("Leaky faucet")
    expect(page).to have_content("Can we schedule a visit?")
    expect(page).to have_link("View all", href: properties_path)
    expect(page).to have_link("View all work orders")
    expect(page).to have_link("View all messages")
  end

  it "shows expiring leases for landlords" do
    landlord = create(:landlord)
    property = create(:property, landlord: landlord, name: "Sunset Apts")
    unit = create(:unit, property: property, label: "3C")
    tenant = create(:tenant)
    create(
      :lease,
      unit: unit,
      tenant: tenant,
      status: :active,
      end_date: 3.weeks.from_now.to_date
    )

    sign_in_and_visit(landlord)

    expect(page).to have_content("Leases expiring soon")
    expect(page).to have_content("Sunset Apts · 3C")
    expect(page).to have_content(tenant.full_name)
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

  it "warns tenants when a lease is ending soon" do
    tenant = create(:tenant)
    property = create(:property, name: "Pine Place")
    unit = create(:unit, property: property, label: "1A")
    create(
      :lease,
      unit: unit,
      tenant: tenant,
      status: :active,
      end_date: 3.weeks.from_now.to_date
    )

    sign_in_and_visit(tenant)

    expect(page).to have_content("Lease ending soon")
    expect(page).to have_content("Pine Place · 1A")
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
