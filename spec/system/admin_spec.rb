require "rails_helper"

RSpec.describe "Admin console" do
  let(:admin) { create(:admin) }

  it "redirects non-admins with an alert" do
    sign_in_and_visit(create(:landlord), admin_dashboard_path)

    expect(page).to have_content("You are not authorized to perform that action.")
  end

  describe "as an admin" do
    before { sign_in_and_visit(admin) }

    it "shows the admin console overview and tabs" do
      click_link "Admin"

      expect(page).to have_content("Admin console")
      expect(page).to have_link("Overview")
      expect(page).to have_link("Users")
      expect(page).to have_link("Properties")
      expect(page).to have_link("Work orders")
      expect(page).to have_link("Conversations")
      expect(page).to have_content("Users by role")
    end

    it "creates a user" do
      visit admin_users_path
      click_link "New user"

      fill_in "First name", with: "New"
      fill_in "Last name", with: "Admin"
      select "Admin", from: "Role"
      fill_in "Email", with: "newadmin@example.com"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Save"

      expect(page).to have_content("User created.")
      expect(page).to have_content("New Admin")
    end

    it "prevents an admin from deleting their own account" do
      visit admin_user_path(admin)
      expect(page).not_to have_button("Delete")

      page.driver.delete admin_user_path(admin)
      visit admin_users_path

      expect(page).to have_content("You cannot delete your own account.")
    end

    it "edits another user" do
      user = create(:landlord, first_name: "Before", last_name: "Edit")
      visit edit_admin_user_path(user)

      fill_in "First name", with: "After"
      click_button "Save"

      expect(page).to have_content("User updated.")
      expect(page).to have_content("After Edit")
    end

    it "deletes another user", js: true do
      user = create(:tenant, first_name: "Delete", last_name: "Me")
      visit admin_user_path(user)

      accept_confirm("Delete this user?") do
        click_button "Delete"
      end

      expect(page).to have_content("User deleted.")
      expect(page).not_to have_content("Delete Me")
    end

    it "shows read-only property and work order lists" do
      landlord = create(:landlord)
      property = create(:property, landlord: landlord, name: "Admin View Property")
      unit = create(:unit, property: property)
      work_order = create(:work_order, unit: unit, title: "Admin View Job")
      conversation = Conversation.direct_between!(create(:tenant), landlord)
      conversation.messages.create!(author: landlord, body: "Admin preview")

      visit admin_properties_path
      click_link "Admin View Property"

      expect(page).to have_content("Admin View Property")
      expect(page).to have_link("Back to properties")

      visit admin_work_orders_path
      click_link "Admin View Job"

      expect(page).to have_content("Admin View Job")

      visit admin_conversations_path
      expect(page).to have_content("Direct message")
      click_link "Direct message"

      expect(page).to have_content("Admin preview")
      expect(page).to have_link("Back to conversations")
    end
  end
end
