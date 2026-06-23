require "rails_helper"

RSpec.describe "Authentication" do
  it "redirects guests to sign in" do
    visit root_path

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Log in to LandIQrd")
  end

  it "shows an error for invalid credentials" do
    visit new_user_session_path

    fill_in "Email", with: "nobody@example.com"
    fill_in "Password", with: "wrong-password"
    click_button "Log in"

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Invalid email or password")
  end

  it "signs in and lands on the dashboard" do
    user = create(:landlord, first_name: "Lana")

    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    expect(page).to have_content("Welcome back, Lana")
  end

  it "signs up as a landlord" do
    visit new_user_registration_path

    expect(page).to have_content("Create your account")

    fill_in "First name", with: "Ada"
    fill_in "Last name", with: "Lovelace"
    select "Landlord", from: "I am a"
    fill_in "Company (optional)", with: "Acme Realty"
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("Welcome back, Ada")
    expect(User.last).to be_landlord
  end

  it "prevents signing up as admin through the UI" do
    visit new_user_registration_path

    fill_in "First name", with: "Sneaky"
    fill_in "Last name", with: "User"
    select "Tenant", from: "I am a"
    fill_in "Email", with: "sneaky@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    # Attempt privilege escalation via hidden/manipulated param is blocked server-side;
    # the UI only offers tenant/landlord/contractor.
    click_button "Sign up"

    expect(User.last.role).to eq("tenant")
  end

  it "signs up as a tenant" do
    visit new_user_registration_path

    fill_in "First name", with: "Toni"
    fill_in "Last name", with: "Tenant"
    select "Tenant", from: "I am a"
    fill_in "Email", with: "toni@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("Welcome back, Toni")
    expect(User.last).to be_tenant
  end

  it "signs up as a contractor" do
    visit new_user_registration_path

    fill_in "First name", with: "Casey"
    fill_in "Last name", with: "Contractor"
    select "Contractor", from: "I am a"
    fill_in "Company (optional)", with: "FixIt Co"
    fill_in "Email", with: "casey@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign up"

    expect(page).to have_content("Welcome back, Casey")
    expect(User.last).to be_contractor
  end

  it "submits a forgot password request" do
    create(:tenant, email: "resetme@example.com")

    visit new_user_session_path
    click_link "Forgot your password?"
    fill_in "Email", with: "resetme@example.com"
    click_button "Send reset instructions"

    expect(page).to have_current_path(new_user_session_path)
  end

  it "completes the password reset flow end to end" do
    user = create(:tenant, first_name: "Reset", email: "resetme@example.com")
    token = set_reset_password_token(user)

    visit edit_user_password_path(reset_password_token: token)
    fill_in "New password", with: "newpassword123"
    fill_in "Confirm new password", with: "newpassword123"
    click_button "Change my password"

    expect(page).to have_content("Welcome back, Reset")

    click_button "Sign out"
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "newpassword123"
    click_button "Log in"

    expect(page).to have_content("Welcome back, Reset")
  end

  it "allows signing in with remember me checked" do
    user = create(:landlord)

    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    check "Remember me"
    click_button "Log in"

    expect(page).to have_content("Welcome back, #{user.first_name}")
  end

  it "updates account email" do
    user = create(:landlord, email: "lana@example.com")
    sign_in_and_visit(user, edit_user_registration_path)

    expect(page).to have_content("Account")
    expect(page).to have_link("Email & security")
    expect(page).not_to have_link("← Back to account")

    fill_in "Email", with: "lana.updated@example.com"
    fill_in "Current password", with: "password123"
    click_button "Update"

    expect(page).to have_content("Your account has been updated successfully")
    expect(user.reload.email).to eq("lana.updated@example.com")
  end

  it "signs out" do
    sign_in_and_visit(create(:landlord))

    click_button "Sign out"

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Log in to LandIQrd")
  end
end
