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
    create(:lease, unit: unit, tenant: tenant, status: :active)
    work_order = create(:work_order, unit: unit, created_by: tenant, status: :open, title: "Broken heater")
    conversation = Conversation.direct_between!(tenant, landlord)
    conversation.messages.create!(author: landlord, body: "I'll send someone over.")

    sign_in_and_visit(tenant)

    expect(page).to have_content("Your leases")
    expect(page).to have_content("My work requests")
    expect(page).to have_content("Conversations")
    expect(page).to have_content("Oak Apartments · 2B")
    expect(page).to have_content("Work order")
    expect(page).to have_content("Broken heater")
    expect(page).to have_content("I'll send someone over.")
    expect(page).to have_link("New work request")
    expect(page).to have_link("View all work requests", href: work_orders_path(status: "active"))
    expect(page).to have_link("View all messages")
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

    expect(page).to have_content("Your leases")
    expect(page).to have_content("Pine Place · 1A")
    expect(page).to have_content("Expiring soon")
    expect(page).not_to have_content("Leases expiring soon")
  end

  describe "tenant dashboard" do
    it "shows empty states when the tenant has no leases, work orders, or conversations" do
      sign_in_and_visit(create(:tenant))

      expect(page).to have_content("No active leases yet")
      expect(page).to have_content("No work requests right now")
      expect(page).to have_content("No conversations yet")
      expect(page).to have_link("New work request")
    end

    it "lists only active leases on the dashboard" do
      tenant = create(:tenant)
      active_property = create(:property, name: "Active Home")
      active_unit = create(:unit, property: active_property, label: "1A")
      create(:lease, unit: active_unit, tenant: tenant, status: :active)

      ended_property = create(:property, name: "Former Home")
      ended_unit = create(:unit, property: ended_property, label: "9Z")
      create(:lease, unit: ended_unit, tenant: tenant, status: :ended)

      sign_in_and_visit(tenant)

      expect(page).to have_content("Active Home · 1A")
      expect(page).not_to have_content("Former Home · 9Z")
      expect(page).to have_content("1 active lease")
    end

    it "shows expiring soon and work order tags on the same lease" do
      tenant = create(:tenant)
      property = create(:property, name: "Maple Court")
      unit = create(:unit, property: property, label: "1A")
      create(:lease, unit: unit, tenant: tenant, status: :active, end_date: 3.weeks.from_now.to_date)
      create(:work_order, unit: unit, created_by: tenant, status: :open)

      sign_in_and_visit(tenant)

      within_dashboard_panel("Your leases") do
        within(find("a", text: /Maple Court · 1A/)) do
          expect(page).to have_content("Expiring soon")
          expect(page).to have_content("Work order")
        end
      end
    end

    it "shows no lease tags when the lease is stable with no open work orders" do
      tenant = create(:tenant)
      property = create(:property, name: "Stable Apts")
      unit = create(:unit, property: property, label: "4D")
      create(:lease, unit: unit, tenant: tenant, status: :active, end_date: 1.year.from_now.to_date)

      sign_in_and_visit(tenant)

      within_dashboard_panel("Your leases") do
        within(find("a", text: /Stable Apts · 4D/)) do
          expect(page).not_to have_content("Expiring soon")
          expect(page).not_to have_content("Work order")
        end
      end
    end

    it "does not show a work order tag when only completed work orders exist on the unit" do
      tenant = create(:tenant)
      property = create(:property, name: "Quiet Apts")
      unit = create(:unit, property: property, label: "2C")
      create(:lease, unit: unit, tenant: tenant, status: :active)
      create(:work_order, unit: unit, created_by: tenant, status: :completed, title: "Old repair")

      sign_in_and_visit(tenant)

      within_dashboard_panel("Your leases") do
        within(find("a", text: /Quiet Apts · 2C/)) do
          expect(page).not_to have_content("Work order")
        end
      end
      expect(page).not_to have_content("Old repair")
      expect(page).to have_content("No work requests right now")
    end

    it "shows work request count badge and request metadata" do
      tenant = create(:tenant)
      property = create(:property, name: "Oak Tower")
      unit = create(:unit, property: property, label: "5A")
      create(:lease, unit: unit, tenant: tenant, status: :active)
      create(:work_order, unit: unit, created_by: tenant, status: :open, title: "No hot water", priority: :high)
      create(:work_order, unit: unit, created_by: tenant, status: :pending_management, title: "Broken lock", priority: :low)

      sign_in_and_visit(tenant)

      expect(page).to have_content("2 active")
      expect(page).to have_content("No hot water")
      expect(page).to have_content("Broken lock")
      expect(page).to have_content("Oak Tower · 5A")
      expect(page).to have_content("Open")
      expect(page).to have_content("Pending Management")
      expect(page).to have_content("High priority")
      expect(page).to have_content("Low priority")
    end

    it "shows an unread badge on the conversations panel" do
      tenant = create(:tenant)
      landlord = create(:landlord)
      conversation = Conversation.direct_between!(tenant, landlord)
      conversation.messages.create!(author: landlord, body: "Checking in")

      sign_in_and_visit(tenant)

      expect(page).to have_content("1 unread")
      expect(page).to have_content("Checking in")
    end
  end

  it "shows contractor assigned work panel and conversations" do
    contractor = create(:contractor)
    landlord = create(:landlord)
    property = create(:property, landlord: landlord)
    unit = create(:unit, property: property)
    work_order = create(:work_order, unit: unit, title: "Fix broken pipe")
    create(:work_order_assignment, work_order: work_order, contractor: contractor)
    conversation = Conversation.direct_between!(landlord, contractor)
    conversation.messages.create!(author: landlord, body: "Can you start tomorrow?")

    sign_in_and_visit(contractor)

    expect(page).to have_content("Assigned work orders")
    expect(page).to have_content("Fix broken pipe")
    expect(page).to have_content("Conversations")
    expect(page).to have_content("Can you start tomorrow?")
    expect(page).not_to have_link("View assigned work")
    expect(page).to have_link("View all assigned work", href: work_orders_path(status: "active"))
    expect(page).to have_link("Assigned Work", href: work_orders_path(status: "active"))
    expect(page).to have_link("View all messages")
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
