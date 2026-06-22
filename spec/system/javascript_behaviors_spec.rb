require "rails_helper"

RSpec.describe "JavaScript behaviors", js: true do
  let(:landlord) { create(:landlord) }

  before { sign_in_and_visit(landlord) }

  it "auto-dismisses flash toasts after a few seconds" do
    visit new_property_path

    fill_in "Name", with: "Flash Test Property"
    click_button "Save"

    expect(page).to have_content("Property created.")

    toast = find("[data-flash-auto-dismiss]")
    expect(toast).to be_present

    expect(page).to have_no_css("[data-flash-auto-dismiss]", wait: 7)
  end

  it "shows a turbo confirm dialog before deleting a property" do
    property = create(:property, landlord: landlord, name: "Delete Me")

    visit property_path(property)

    accept_confirm("Delete this property and all its units?") do
      click_button "Delete"
    end

    expect(page).to have_content("Property deleted.")
    expect(page).not_to have_content("Delete Me")
  end

  describe "mobile sidebar" do
    it "toggles open and closed" do
      mobile_viewport
      visit current_path

      find("[aria-label='Open menu']").click

      within("aside") do
        expect(page).to have_link("Properties", visible: :all)
      end

      find("[data-sidebar-target='overlay']").click

      expect(page).to have_selector("aside.-translate-x-full", visible: :all)
    end
  end
end
