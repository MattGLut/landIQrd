require "rails_helper"

RSpec.describe "Work orders" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property, label: "Apt 1A") }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }

  describe "as a tenant" do
    before { sign_in_and_visit(tenant) }

    it "shows my requests and submits a new work request" do
      expect(page).to have_content("My Requests")
      expect(page).to have_link("New work request")

      click_link "New work request"
      select unit.full_label, from: "Unit"
      fill_in "Title", with: "No heat"
      fill_in "Description", with: "Radiator is cold."
      select "High", from: "Priority"
      click_button "Save"

      expect(page).to have_content("Work request submitted.")
      expect(page).to have_content("No heat")
    end
  end

  describe "as a landlord" do
    before { sign_in_and_visit(landlord) }

    it "shows work orders with status filters" do
      open_order = create(:work_order, unit: unit, created_by: tenant, title: "Open job", status: :open)
      create(:work_order, unit: unit, created_by: tenant, title: "Done job", status: :completed)

      visit work_orders_path

      expect(page).to have_content("Work Orders")
      expect(page).to have_content("Open job")
      expect(page).to have_content("Done job")

      click_link "Completed"

      expect(page).to have_content("Done job")
      expect(page).not_to have_content("Open job")

      click_link "Active"

      expect(page).to have_content("Open job")
    end

    it "filters cancelled work orders" do
      create(:work_order, unit: unit, created_by: tenant, title: "Cancelled job", status: :cancelled)
      create(:work_order, unit: unit, created_by: tenant, title: "Active job", status: :open)

      visit work_orders_path
      click_link "Cancelled"

      expect(page).to have_content("Cancelled job")
      expect(page).not_to have_content("Active job")
    end

    it "removes a contractor assignment" do
      contractor = create(:contractor, company_name: "FixIt Co")
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Remove assignment")
      create(:work_order_assignment, work_order: work_order, contractor: contractor)

      visit work_order_path(work_order)
      click_button "Remove"

      expect(page).to have_content("Assignment removed.")
      expect(page).to have_content("No contractors assigned yet.")
    end

    it "assigns a contractor on the show page" do
      contractor = create(:contractor, first_name: "Casey", last_name: "Contractor", company_name: "FixIt Co")
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Leaky faucet")

      visit work_order_path(work_order)

      select contractor.display_name, from: "Contractor"
      click_button "Assign"

      expect(page).to have_content("Contractor assigned.")
      expect(page).to have_content("FixIt Co")
    end

    it "updates work order status from the show page dropdown", js: true do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Broken window")

      visit work_order_path(work_order)
      find("[aria-label='Change status']").click
      click_on "Pending Management"

      expect(page).to have_content("Work order updated.")
      expect(find("[aria-label='Change status']")).to have_content("Pending Management")
    end

    it "does not show a delete button", js: true do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Keep me")

      visit work_order_path(work_order)
      expect(page).not_to have_button("Delete")
    end

    it "cancels a work order with an optional reason", js: true do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Cancel me")

      visit work_order_path(work_order)
      find("[aria-label='Change status']").click
      click_on "Cancelled"
      fill_in "Reason", with: "Duplicate request"
      click_button "Update status"

      expect(page).to have_content("Work order updated.")
      expect(page).to have_content("Duplicate request")
      expect(page).not_to have_css("[aria-label='Change status']")
    end

    it "closes a work order with a required reason", js: true do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Close me")

      visit work_order_path(work_order)
      find("[aria-label='Change status']").click
      click_on "Closed"
      fill_in "Reason", with: "Tenant fixed it"
      click_button "Update status"

      expect(page).to have_content("Work order closed.")
      expect(page).to have_content("Tenant fixed it")
      expect(page).not_to have_css("[aria-label='Change status']")
    end

    it "reopens a completed work order", js: true do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Still broken", status: :completed)

      visit work_order_path(work_order)
      find("[aria-label='Change status']").click
      click_on "Reopen"

      expect(page).to have_content("Work order reopened.")
      expect(find("[aria-label='Change status']")).to have_content("Pending Management")
    end
  end

  describe "as a contractor" do
    let(:contractor) { create(:contractor) }

    before { sign_in_and_visit(contractor) }

    it "does not offer new work request creation" do
      visit work_orders_path

      expect(page).to have_content("Assigned Work")
      expect(page).not_to have_link("New work request")
    end

    it "shows only assigned work orders" do
      assigned = create(:work_order, unit: unit, created_by: tenant, title: "Assigned job")
      create(:work_order_assignment, work_order: assigned, contractor: contractor)
      create(:work_order, unit: unit, created_by: tenant, title: "Unassigned job")

      visit work_orders_path

      expect(page).to have_content("Assigned Work")
      expect(page).to have_content("Assigned job")
      expect(page).not_to have_content("Unassigned job")
    end

    it "updates assignment status" do
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Fix outlet")
      create(:work_order_assignment, work_order: work_order, contractor: contractor, status: :accepted)

      visit work_order_path(work_order)
      select "Completed", from: "work_order_assignment_status"
      click_button "Update"

      expect(page).to have_content("Assignment updated.")
      expect(page).to have_content("Completed")
    end
  end

  describe "deleting a work order", js: true do
    it "lets an admin confirm deletion via turbo dialog" do
      admin = create(:admin)
      sign_in_and_visit(admin)
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Remove me")

      visit work_order_path(work_order)
      accept_confirm("Delete this work order?") do
        click_button "Delete"
      end

      expect(page).to have_content("Work order deleted.")
      expect(page).not_to have_content("Remove me")
    end
  end

  describe "closing a work order as tenant", js: true do
    it "closes the request with a reason instead of deleting" do
      sign_in_and_visit(tenant)
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Close me")

      visit work_order_path(work_order)
      expect(page).not_to have_button("Delete")
      find("[aria-label='Change status']").click
      click_on "Closed"
      fill_in "Reason", with: "Fixed it myself"
      click_button "Update status"

      expect(page).to have_content("Work request closed.")
      expect(page).to have_content("Fixed it myself")
      expect(page).not_to have_css("[aria-label='Change status']")
    end
  end

  describe "reopening a completed work order as tenant", js: true do
    it "reopens the request when the fix did not hold" do
      sign_in_and_visit(tenant)
      work_order = create(:work_order, unit: unit, created_by: tenant, title: "Still leaking", status: :completed)

      visit work_order_path(work_order)
      find("[aria-label='Change status']").click
      click_on "Reopen"

      expect(page).to have_content("Work request reopened.")
      expect(find("[aria-label='Change status']")).to have_content("Pending Management")
    end
  end
end
