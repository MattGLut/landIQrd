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
end
