require "rails_helper"

RSpec.describe "Units" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord, name: "Maple Court") }

  before do
    sign_in_and_visit(landlord, property_path(property))
  end

  it "adds a unit from the property page" do
    click_link "Add unit"

    fill_in "Unit label", with: "Apt 1A"
    fill_in "Bedrooms", with: "2"
    fill_in "Bathrooms", with: "1"
    fill_in "Sq ft", with: "850"
    click_button "Save"

    expect(page).to have_content("Unit added.")
    expect(page).to have_content("Apt 1A")
    expect(page).to have_content("850 sqft")
  end

  it "navigates to unit show, edits, and deletes" do
    unit = create(:unit, property: property, label: "Apt 2B", bedrooms: 1, bathrooms: 1, square_feet: 650)

    visit property_path(property)
    click_link "Apt 2B"

    expect(page).to have_content("Apt 2B")
    expect(page).to have_content("Maple Court")
    expect(page).to have_content("Leases")

    click_link "Edit"
    fill_in "Unit label", with: "Apt 2B Updated"
    click_button "Save"

    expect(page).to have_content("Unit updated.")
    expect(page).to have_content("Apt 2B Updated")

    click_link "Apt 2B Updated"
    click_button "Delete"

    expect(page).to have_content("Unit removed.")
    expect(page).to have_content("Maple Court")
  end
end
