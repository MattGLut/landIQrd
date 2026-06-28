require "rails_helper"

RSpec.describe "Contractor portfolio" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }
  let(:contractor) { create(:contractor, company_name: "FixIt Co", website_url: "https://fixit.example.com") }

  def upload_path(name)
    Rails.root.join("spec/fixtures/files", name).to_s
  end

  it "lets a contractor manage business profile and portfolio" do
    sign_in_and_visit(contractor, edit_contractor_business_profile_path)

    fill_in "Company name", with: "FixIt Co"
    fill_in "Website", with: "https://fixit.example.com"
    click_button "Save business profile"

    expect(page).to have_content("Business profile updated.")
    click_link "Manage portfolio"
    visit new_contractor_portfolio_item_path

    fill_in "Title", with: "Emergency pipe repair"
    fill_in "Description", with: "Replaced burst pipe in apartment building."
    select "Plumbing", from: "Trade / category"
    attach_file "Photos", upload_path("sample.png")
    click_button "Add portfolio item"

    expect(page).to have_content("Portfolio item added.")
    expect(page).to have_content("Emergency pipe repair")
  end

  it "lets a landlord browse contractors and view a portfolio" do
    create(:contractor_portfolio_item, contractor: contractor, title: "Boiler service", category: "hvac")

    sign_in_and_visit(landlord, contractors_path)

    expect(page).to have_link("Contractors")
    expect(page).to have_content("FixIt Co")
    click_link "FixIt Co"

    expect(page).to have_content("Boiler service")
    expect(page).to have_link("https://fixit.example.com")
  end

  it "shows relevant contractors first when assigning work" do
    matching = create(:contractor, company_name: "Pipe Pros")
    create(:contractor_portfolio_item, contractor: matching, category: "plumbing", title: "Pipe job")
    other = create(:contractor, company_name: "Random Co")
    work_order = create(:work_order, unit: unit, created_by: tenant, category: :plumbing, title: "Leaky pipe")

    sign_in_and_visit(landlord, work_order_path(work_order))

    expect(page).to have_content("Assign a contractor")
    expect(page).to have_link("View portfolio", href: contractor_path(matching))
    expect(page).to have_content("1 relevant project")
    expect(page).to have_content("Pipe Pros")

    within("[data-contractor-picker-row]", text: "Pipe Pros") do
      click_button "Assign"
    end

    expect(page).to have_content("Contractor assigned.")
    expect(page).to have_content("Pipe Pros")
    expect(page).to have_content("Random Co")
  end

  it "filters the assignment picker to relevant contractors" do
    matching = create(:contractor, company_name: "Pipe Pros")
    create(:contractor_portfolio_item, contractor: matching, category: "plumbing", title: "Pipe job")
    create(:contractor, company_name: "Random Co")
    work_order = create(:work_order, unit: unit, created_by: tenant, category: :plumbing, title: "Leaky pipe")

    sign_in_and_visit(landlord, work_order_path(work_order))
    click_link "Relevant only"

    expect(page).to have_content("Pipe Pros")
    expect(page).not_to have_content("Random Co")
  end

  it "lets a contractor edit and delete a portfolio item", js: true do
    item = create(:contractor_portfolio_item, contractor: contractor, title: "Old showcase")
    sign_in_and_visit(contractor, contractor_portfolio_items_path)

    click_link "Edit"
    fill_in "Title", with: "Updated showcase"
    click_button "Save changes"

    expect(page).to have_content("Portfolio item updated.")
    expect(page).to have_content("Updated showcase")

    accept_confirm("Remove this portfolio item?") do
      click_button "Delete"
    end

    expect(page).to have_content("Portfolio item removed.")
    expect(page).not_to have_content("Updated showcase")
    expect(ContractorPortfolioItem.exists?(item.id)).to be(false)
  end

  it "links to business profile from account settings" do
    sign_in_and_visit(contractor, edit_account_path)

    expect(page).to have_link("Business profile", href: edit_contractor_business_profile_path)
    visit edit_contractor_business_profile_path

    expect(page).to have_content("Business profile")
    expect(page).to have_link("Manage portfolio")
  end
end
