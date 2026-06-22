require "rails_helper"

RSpec.describe "Leases", type: :request do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }

  describe "GET /leases/:id" do
    it "allows the tenant to view their lease" do
      lease = create(:lease, unit: unit, tenant: tenant)
      sign_in tenant
      get lease_path(lease)
      expect(response).to have_http_status(:ok)
    end

    it "allows the owning landlord to view the lease" do
      lease = create(:lease, unit: unit, tenant: tenant)
      sign_in landlord
      get lease_path(lease)
      expect(response).to have_http_status(:ok)
    end

    it "blocks an unrelated tenant" do
      lease = create(:lease, unit: unit, tenant: tenant)
      sign_in create(:tenant)
      get lease_path(lease)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /units/:unit_id/leases" do
    it "creates a lease for the owning landlord" do
      sign_in landlord
      expect {
        post unit_leases_path(unit), params: {
          lease: {
            tenant_id: tenant.id,
            start_date: Date.current,
            end_date: 1.year.from_now.to_date,
            rent_amount: 1500,
            deposit_amount: 1500,
            status: "active"
          }
        }
      }.to change(unit.leases, :count).by(1)
      expect(response).to redirect_to(Lease.last)
    end
  end

  describe "PATCH /leases/:id" do
    it "updates a lease for the owning landlord" do
      lease = create(:lease, unit: unit, tenant: tenant, rent_amount: 1500)
      sign_in landlord
      patch lease_path(lease), params: { lease: { rent_amount: 1600 } }
      expect(lease.reload.rent_amount).to eq(1600)
    end
  end

  describe "DELETE /leases/:id" do
    it "deletes a lease for the owning landlord" do
      lease = create(:lease, unit: unit, tenant: tenant)
      sign_in landlord
      expect {
        delete lease_path(lease)
      }.to change(Lease, :count).by(-1)
      expect(response).to redirect_to(property)
    end
  end

  describe "lease documents" do
    it "downloads an attached document" do
      lease = create(:lease, unit: unit, tenant: tenant)
      lease.documents.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
      sign_in landlord
      get rails_blob_path(lease.documents.first, disposition: "attachment")

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("sample.pdf")
    end
  end
end
