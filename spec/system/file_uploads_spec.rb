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

    visit work_order_path(WorkOrder.last)
    expect(page).to have_css("img[alt='sample.png']")
  end

  it "shows existing photos on the work order edit form" do
    work_order = create(:work_order, unit: unit, created_by: tenant, title: "Broken window")
    work_order.photos.attach(
      io: File.open(upload_path("sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    sign_in_and_visit(tenant, edit_work_order_path(work_order))

    expect(page).to have_css("img[alt='sample.png']")
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

  it "downloads a lease document" do
    lease.documents.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
      filename: "sample.pdf",
      content_type: "application/pdf"
    )

    sign_in_and_visit(landlord, lease_path(lease))
    click_link "Download"

    expect(page.status_code).to be_in([ 200, 302 ])
    if page.status_code == 302
      visit page.response_headers["Location"]
    end
    expect(page.response_headers["Content-Type"]).to include("application/pdf")
  end
end
