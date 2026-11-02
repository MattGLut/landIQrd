require "rails_helper"

RSpec.describe "Quick jobs" do
  let(:landlord) { create(:landlord, first_name: "Lana", last_name: "Landlord", company_name: "Lana Properties") }
  let(:property) { create(:property, landlord: landlord, name: "Maple Court") }
  let!(:unit) { create(:unit, property: property, label: "Apt 1A") }
  let(:contractor) { create(:contractor, company_name: "FixIt Co", first_name: "Casey", last_name: "Cole") }

  it "waits for the contractor to accept the contact and the job" do
    sign_in_and_visit(landlord, contractor_path(contractor))

    select "Business", from: "Relationship"
    click_button "Send request"

    expect(page).to have_content("Request sent.")
    expect(page).to have_content("Awaiting acceptance")
    expect(page).not_to have_link("Assign a quick job")

    sign_in_and_visit(contractor, contractor_relationships_path)
    expect(page).to have_content("Lana Properties")
    click_button "Accept"

    expect(page).to have_content("Contact accepted.")
    expect(page).to have_content("Accepted")

    sign_in_and_visit(landlord, new_quick_job_path(contractor_id: contractor.id))
    select "FixIt Co · Business contact", from: "Contractor"
    select unit.full_label, from: "Unit"
    fill_in "Title", with: "Replace the faucet"
    fill_in "Description", with: "Kitchen sink faucet is loose."
    select "Plumbing", from: "Category"
    select "High", from: "Priority"
    fill_in "Agreed price", with: "250"
    click_button "Assign job"

    expect(page).to have_content("Job sent to FixIt Co.")
    expect(page).to have_content("They need to accept it.")
    expect(page).to have_content("Pending")
    expect(page).to have_content("sent this job directly to FixIt Co (business contact)")
    expect(Job.count).to eq(0)

    sign_in_and_visit(contractor, work_order_path(WorkOrder.last))
    click_button "Accept job"

    expect(page).to have_content("Job accepted.")
    expect(page).to have_content("Accepted")
    expect(page).not_to have_button("Accept job")
  end

  it "offers quick job from the work order list" do
    sign_in_and_visit(landlord, work_orders_path)
    expect(page).to have_link("Quick job", href: new_quick_job_path)
  end

  it "hides quick job from tenants" do
    tenant = create(:tenant)
    sign_in_and_visit(tenant, work_orders_path)
    expect(page).not_to have_link("Quick job")
  end
end
