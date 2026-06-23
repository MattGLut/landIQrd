require "rails_helper"

RSpec.describe "Accounts" do
  let(:tenant) { create(:tenant, first_name: "Toni", preferred_name: nil) }

  before { sign_in_and_visit(tenant, edit_account_path) }

  it "shows the unified account settings shell" do
    expect(page).to have_content("Account")
    expect(page).to have_content("Manage your profile and settings")
    expect(page).to have_link("Profile")
    expect(page).to have_link("Notifications")
    expect(page).to have_link("Email & security")
    expect(page).to have_content("Profile", count: 2)
  end

  it "updates preferred name" do
    fill_in "Preferred name", with: "T-Dawg"
    click_button "Save profile"

    expect(page).to have_content("Profile updated.")
    expect(page).to have_field("Preferred name", with: "T-Dawg")
    expect(tenant.reload.preferred_name).to eq("T-Dawg")
  end

  it "updates notification preferences", js: true do
    visit notifications_account_path

    expect(page).to have_content("Account")
    expect(page).to have_link("Notifications")
    expect(page).to have_content("Email notifications")
    uncheck "email_notification_preference_new_message"

    expect(page).to have_unchecked_field("email_notification_preference_new_message")
    expect(tenant.reload.email_notification_preferences).to include("new_message" => false)
  end

  describe "notification preferences", js: true do
    it "disables all notification types with the master toggle" do
      visit notifications_account_path

      uncheck "email_notification_preference_all"

      expect(page).to have_unchecked_field("email_notification_preference_work_order_status_changed")
      expect(page).to have_unchecked_field("email_notification_preference_new_message")
      expect(page).to have_unchecked_field("email_notification_preference_lease_expiring")
      expect(tenant.reload.email_notification_preferences).to eq(
        "work_order_status_changed" => false,
        "new_message" => false,
        "lease_expiring" => false
      )
    end

    it "enables all notification types with the master toggle" do
      tenant.update!(email_notification_preferences: {
        "work_order_status_changed" => false,
        "new_message" => false,
        "lease_expiring" => false
      })
      visit notifications_account_path

      check "email_notification_preference_all"

      expect(page).to have_checked_field("email_notification_preference_work_order_status_changed")
      expect(page).to have_checked_field("email_notification_preference_new_message")
      expect(page).to have_checked_field("email_notification_preference_lease_expiring")
      expect(tenant.reload.email_notification_preferences).to eq(
        "work_order_status_changed" => true,
        "new_message" => true,
        "lease_expiring" => true
      )
    end

    it "shows landlord notification types only" do
      landlord = create(:landlord)
      sign_in_and_visit(landlord, notifications_account_path)

      expect(page).to have_content("New work requests")
      expect(page).to have_content("Work order updates")
      expect(page).to have_content("New messages")
      expect(page).to have_content("Lease invitation accepted")
      expect(page).to have_content("Lease ended")
      expect(page).not_to have_content("Work order assignments")
    end

    it "shows contractor notification types only" do
      contractor = create(:contractor)
      sign_in_and_visit(contractor, notifications_account_path)

      expect(page).to have_content("Work order updates")
      expect(page).to have_content("Work order assignments")
      expect(page).to have_content("New messages")
      expect(page).not_to have_content("New work requests")
      expect(page).not_to have_content("Lease invitation accepted")
      expect(page).not_to have_content("Lease ended")
    end
  end
end
