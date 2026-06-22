require "rails_helper"

RSpec.describe "Navigation" do
  describe "sidebar links" do
    it "shows landlord navigation" do
      sign_in_and_visit(create(:landlord))

      within("aside") do
        expect(page).to have_link("Properties")
        expect(page).to have_link("Work Orders")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Admin")
      end
    end

    it "shows tenant navigation" do
      sign_in_and_visit(create(:tenant))

      within("aside") do
        expect(page).to have_link("My Requests")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Properties")
      end
    end

    it "shows contractor navigation" do
      sign_in_and_visit(create(:contractor))

      within("aside") do
        expect(page).to have_link("Assigned Work")
        expect(page).to have_link("Messages")
      end
    end

    it "shows admin footer link" do
      sign_in_and_visit(create(:admin))

      within("aside") do
        expect(page).to have_link("Admin")
      end
    end
  end

  describe "sidebar navigation clicks" do
    let(:landlord) { create(:landlord) }

    before { sign_in_and_visit(landlord) }

    it "navigates to properties" do
      click_link "Properties", match: :first

      expect(page).to have_content("Properties")
      expect(page).to have_link("New property")
    end

    it "navigates to work orders" do
      click_link "Work Orders"

      expect(page).to have_content("Work Orders")
    end

    it "navigates to messages" do
      click_link "Messages"

      expect(page).to have_content("Select a conversation to view messages")
    end
  end

  it "navigates from dashboard manage properties CTA" do
    sign_in_and_visit(create(:landlord))

    click_link "Manage properties"

    expect(page).to have_content("Properties")
  end

  describe "mobile sidebar", js: true do
    it "opens and closes the sidebar menu" do
      sign_in_and_visit(create(:landlord))
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
