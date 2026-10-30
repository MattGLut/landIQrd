require "rails_helper"

RSpec.describe "Navigation" do
  describe "top navigation links" do
    it "shows landlord navigation" do
      sign_in_and_visit(create(:landlord))

      within("aside nav[aria-label='Main']") do
        expect(page).to have_link("Properties")
        expect(page).to have_link("Contractors")
        expect(page).to have_link("Work Orders")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Admin")
      end
    end

    it "shows tenant navigation" do
      sign_in_and_visit(create(:tenant))

      within("aside nav[aria-label='Main']") do
        expect(page).to have_link("My Requests")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Properties")
      end
    end

    it "shows contractor navigation" do
      sign_in_and_visit(create(:contractor))

      within("aside nav[aria-label='Main']") do
        expect(page).to have_link("Assigned Work", href: work_orders_path(status: "active"))
        expect(page).to have_link("Portfolio", href: contractor_portfolio_items_path)
        expect(page).to have_link("Schedule")
        expect(page).to have_link("Messages")
        expect(page).not_to have_link("Contractors")
      end
    end

    it "shows admin link" do
      sign_in_and_visit(create(:admin))

      within("aside nav[aria-label='Main']") do
        expect(page).to have_link("Dashboard", href: admin_dashboard_path)
      end
    end
  end

  describe "top navigation clicks" do
    let(:landlord) { create(:landlord) }

    before { sign_in_and_visit(landlord) }

    it "navigates to properties" do
      within("aside nav[aria-label='Main']") { click_link "Properties" }

      expect(page).to have_content("Properties")
      expect(page).to have_link("New property")
    end

    it "navigates to work orders" do
      within("aside nav[aria-label='Main']") { click_link "Work Orders" }

      expect(page).to have_content("Work Orders")
    end

    it "navigates to messages" do
      within("aside nav[aria-label='Main']") { click_link "Messages" }

      expect(page).to have_content("Select a conversation to view messages")
    end
  end

  it "navigates from dashboard properties panel" do
    sign_in_and_visit(create(:landlord))

    click_link "View all", match: :first

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

  describe "account menu", js: true do
    let(:landlord) { create(:landlord, first_name: "Lana") }

    # iPhone Safari never applies a lasting :hover, so the menu has to open on tap.
    it "opens on tap and stays open after hover and focus drop" do
      sign_in_and_visit(landlord)
      mobile_viewport
      visit current_path

      expect(page).to have_css("#account-menu.hidden", visible: :all)

      find("[aria-controls='account-menu']").click
      page.execute_script("document.activeElement.blur()")
      find("main").hover

      click_link "Account settings"
      expect(page).to have_current_path(edit_account_path)
    end

    it "signs out from a phone" do
      sign_in_and_visit(landlord)
      mobile_viewport
      visit current_path

      sign_out_via_header

      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
