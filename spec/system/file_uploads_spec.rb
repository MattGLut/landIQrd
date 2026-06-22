require "rails_helper"

RSpec.describe "File uploads" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }

  def upload_path(name)
    Rails.root.join("spec/fixtures/files", name).to_s
  end

  it "uploads work order photos" do
    sign_in_and_visit(tenant, new_work_order_path)

    select unit.full_label, from: "Unit"
    fill_in "Title", with: "Broken window"
    page.attach_file("Photos", upload_path("sample.png"))
    click_button "Save"

    expect(page).to have_content("Work request submitted.")
    expect(page).to have_content("Photos")
    expect(WorkOrder.last.photos).to be_attached
  end

  it "uploads lease documents" do
    sign_in_and_visit(landlord, new_unit_lease_path(unit))

    select tenant.full_name, from: "Tenant"
    fill_in "Start date", with: Date.current
    fill_in "End date", with: 1.year.from_now.to_date
    fill_in "Monthly rent", with: "1500"
    fill_in "Security deposit", with: "1500"
    page.attach_file("Lease documents", upload_path("sample.pdf"))
    click_button "Save"

    expect(page).to have_content("Lease created.")
    expect(page).to have_content("sample.pdf")
    expect(Lease.last.documents).to be_attached
  end

  it "uploads a message attachment", js: true do
    conversation = Conversation.direct_between!(tenant, landlord)
    sign_in_and_visit(tenant, conversation_path(conversation))

    page.attach_file("message_files", upload_path("sample.pdf"), make_visible: true)
    click_button "Send"

    expect(page).to have_content("sample.pdf")
    expect(conversation.messages.last.files).to be_attached
  end
end
