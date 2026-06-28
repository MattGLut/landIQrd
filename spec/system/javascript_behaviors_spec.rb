require "rails_helper"

RSpec.describe "JavaScript behaviors", js: true do
  let(:landlord) { create(:landlord) }

  before { sign_in_and_visit(landlord) }

  it "shows flash notices after creating a property" do
    visit new_property_path

    fill_in "Name", with: "Flash Test Property"
    click_button "Save"

    expect(page).to have_content("Property created.")
  end

  it "auto-dismisses flash notices after a few seconds" do
    visit new_property_path

    fill_in "Name", with: "Flash Dismiss Property"
    click_button "Save"

    expect(page).to have_content("Property created.")

    using_wait_time(7) do
      expect(page).to have_no_content("Property created.")
    end
  end

  it "auto-dismisses flash alerts after a few seconds" do
    tenant = create(:tenant)
    sign_in tenant
    visit properties_path

    expect(page).to have_content("You are not authorized to perform that action.")

    using_wait_time(7) do
      expect(page).to have_no_content("You are not authorized to perform that action.")
    end
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

  describe "mobile navigation" do
    it "toggles open and closed" do
      mobile_viewport
      visit current_path

      find("[aria-label='Open main menu']").click

      within("#mobile-nav-panel") do
        expect(page).to have_link("Properties", visible: :all)
      end

      find("[aria-label='Close main menu']").click

      expect(page).to have_css("#mobile-nav-panel.hidden", visible: :all)
    end
  end
end
