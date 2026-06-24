require "rails_helper"

RSpec.describe "Navigation" do
  describe "top navigation links" do
    it "shows landlord navigation" do
      sign_in_and_visit(create(:landlord))

      within("header nav[aria-label='Main']") do
        expect(page).to have_link("Properties")
        expect(page).to have_link("Work Orders")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Admin")
      end
    end

    it "shows tenant navigation" do
      sign_in_and_visit(create(:tenant))

      within("header nav[aria-label='Main']") do
        expect(page).to have_link("My Requests")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Properties")
      end
    end

    it "shows contractor navigation" do
      sign_in_and_visit(create(:contractor))

      within("header nav[aria-label='Main']") do
        expect(page).to have_link("Assigned Work")
        expect(page).to have_link("Messages")
      end
    end

    it "shows admin link" do
      sign_in_and_visit(create(:admin))

      within("header nav[aria-label='Main']") do
        expect(page).to have_link("Admin")
      end
    end
  end

  describe "top navigation clicks" do
    let(:landlord) { create(:landlord) }

    before { sign_in_and_visit(landlord) }

    it "navigates to properties" do
      within("header nav[aria-label='Main']") { click_link "Properties" }

      expect(page).to have_content("Properties")
      expect(page).to have_link("New property")
    end

    it "navigates to work orders" do
      within("header nav[aria-label='Main']") { click_link "Work Orders" }

      expect(page).to have_content("Work Orders")
    end

    it "navigates to messages" do
      within("header nav[aria-label='Main']") { click_link "Messages" }

      expect(page).to have_content("Select a conversation to view messages")
    end
  end

  it "navigates from dashboard manage properties CTA" do
    sign_in_and_visit(create(:landlord))

    click_link "Manage properties"

    expect(page).to have_content("Properties")
  end

  describe "mobile navigation", js: true do
    it "opens and closes the mobile menu" do
      sign_in_and_visit(create(:landlord))
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
