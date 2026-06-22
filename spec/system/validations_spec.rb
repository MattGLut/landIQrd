require "rails_helper"

RSpec.describe "Form validations" do
  let(:landlord) { create(:landlord) }

  before { sign_in_and_visit(landlord) }

  it "shows property validation errors" do
    visit new_property_path
    click_button "Save"

    expect(page).to have_content("error prevented this from being saved")
    expect(page).to have_content("Name can't be blank")
  end

  it "shows work order validation errors" do
    tenant = create(:tenant)
    property = create(:property)
    unit = create(:unit, property: property)
    create(:lease, unit: unit, tenant: tenant)

    sign_in_and_visit(tenant, new_work_order_path)
    select unit.full_label, from: "Unit"
    click_button "Save"

    expect(page).to have_content("error prevented this from being saved")
    expect(page).to have_content("Title can't be blank")
  end

  it "shows lease date validation errors" do
    property = create(:property, landlord: landlord)
    unit = create(:unit, property: property)
    tenant = create(:tenant)

    visit new_unit_lease_path(unit)
    select tenant.full_name, from: "Tenant"
    fill_in "Start date", with: Date.current
    fill_in "End date", with: 1.day.ago.to_date
    fill_in "Monthly rent", with: "1500"
    fill_in "Security deposit", with: "1500"
    click_button "Save"

    expect(page).to have_content("error prevented this from being saved")
    expect(page).to have_content("End date must be after the start date")
  end
end
