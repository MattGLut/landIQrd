require "rails_helper"

RSpec.describe "Lease invitations" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord, name: "Maple Court") }
  let(:unit) { create(:unit, property: property, label: "Apt 2B") }

  before { sign_in_and_visit(landlord, unit_path(unit)) }

  it "lets a landlord invite a tenant by email" do
    click_link "Invite tenant"

    fill_in "Email", with: "newtenant@example.com"
    fill_in "Start date", with: Date.current
    fill_in "End date", with: 1.year.from_now.to_date
    fill_in "Monthly rent", with: "1500"
    fill_in "Security deposit", with: "1500"
    click_button "Send invitation"

    expect(page).to have_content("Invitation sent to newtenant@example.com")
  end

  it "lets an invited guest sign up and accept the invitation" do
    invitation = create(:lease_invitation, unit: unit, invited_by: landlord, email: "guest@example.com")

    sign_out_via_header
    visit invite_path(invitation.token)
    fill_in "First name", with: "Guest"
    fill_in "Last name", with: "Tenant"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("Welcome back, Guest")
    expect(invitation.reload).to be_status_accepted
    expect(User.find_by(email: "guest@example.com")).to be_tenant
  end
end
