require "rails_helper"

RSpec.describe "Accounts" do
  let(:tenant) { create(:tenant, first_name: "Toni", preferred_name: nil) }

  before { sign_in_and_visit(tenant, edit_account_path) }

  it "updates preferred name" do
    fill_in "Preferred name", with: "T-Dawg"
    click_button "Save profile"

    expect(page).to have_content("Profile updated.")
    expect(page).to have_field("Preferred name", with: "T-Dawg")
    expect(tenant.reload.preferred_name).to eq("T-Dawg")
  end
end
