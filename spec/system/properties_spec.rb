require "rails_helper"

RSpec.describe "Properties" do
  let(:landlord) { create(:landlord) }

  before { sign_in_and_visit(landlord, properties_path) }

  it "shows empty state with add property action" do
    expect(page).to have_content("No properties yet. Add your first one to get started.")
    expect(page).to have_link("Add property")
  end

  it "shows empty state with add unit action on property show" do
    property = create(:property, landlord: landlord, name: "Empty Building")

    visit property_path(property)

    expect(page).to have_content("No units yet.")
    expect(page).to have_link("Add unit")
  end

  it "creates, views, edits, and deletes a property" do
    click_link "New property"

    fill_in "Name", with: "Maple Court"
    fill_in "Address", with: "123 Main St"
    fill_in "City", with: "Springfield"
    fill_in "State", with: "IL"
    fill_in "ZIP", with: "62701"
    click_button "Save"

    expect(page).to have_content("Property created.")
    expect(page).to have_content("Maple Court")
    expect(page).to have_content("Units")

    click_link "Edit"
    fill_in "Name", with: "Maple Court Updated"
    click_button "Save"

    expect(page).to have_content("Property updated.")
    expect(page).to have_content("Maple Court Updated")

    click_button "Delete"

    expect(page).to have_content("Property deleted.")
    expect(page).to have_content("No properties yet")
  end

  it "navigates to property show from index card" do
    create(:property, landlord: landlord, name: "Pine Ridge")

    visit properties_path
    click_link "Pine Ridge"

    expect(page).to have_content("Pine Ridge")
    expect(page).to have_content("Units")
  end

  it "denies tenants access to properties" do
    sign_in_and_visit(create(:tenant), properties_path)

    expect(page).to have_content("You are not authorized to perform that action.")
  end
end
