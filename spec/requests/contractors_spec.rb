require "rails_helper"

RSpec.describe "Contractors", type: :request do
  let(:landlord) { create(:landlord) }
  let(:contractor) { create(:contractor, company_name: "FixIt Co", website_url: "https://fixit.example.com") }
  let!(:portfolio_item) { create(:contractor_portfolio_item, contractor: contractor, title: "Pipe repair", category: "plumbing") }

  describe "GET /contractors" do
    it "lets a landlord browse contractors" do
      sign_in landlord
      get contractors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FixIt Co")
    end

    it "filters contractors by portfolio category" do
      other = create(:contractor, company_name: "Cool Air")
      create(:contractor_portfolio_item, contractor: other, category: "hvac", title: "AC install")

      sign_in landlord
      get contractors_path, params: { category: "plumbing" }

      expect(response.body).to include("FixIt Co")
      expect(response.body).not_to include("Cool Air")
    end

    it "forbids tenants" do
      sign_in create(:tenant)
      get contractors_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /contractors/:id" do
    it "shows a contractor portfolio" do
      sign_in landlord
      get contractor_path(contractor)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pipe repair")
      expect(response.body).to include("https://fixit.example.com")
    end
  end
end

RSpec.describe "Contractor portfolio", type: :request do
  let(:contractor) { create(:contractor) }

  describe "PATCH /contractor/business_profile" do
    it "updates business profile fields" do
      sign_in contractor
      patch contractor_business_profile_path, params: {
        user: { company_name: "Pro Plumbing", phone: "555-0100", website_url: "https://pro.example.com" }
      }

      expect(response).to redirect_to(edit_contractor_business_profile_path)
      expect(contractor.reload.company_name).to eq("Pro Plumbing")
      expect(contractor.website_url).to eq("https://pro.example.com")
    end
  end

  describe "POST /contractor/portfolio_items" do
    it "creates a portfolio item" do
      sign_in contractor
      expect {
        post contractor_portfolio_items_path, params: {
          contractor_portfolio_item: {
            title: "Kitchen remodel",
            description: "Full kitchen plumbing refresh",
            category: "plumbing",
            position: 1,
            photos: [ fixture_file_upload("sample.png", "image/png") ]
          }
        }
      }.to change(ContractorPortfolioItem, :count).by(1)

      expect(response).to redirect_to(contractor_portfolio_items_path)
      expect(ContractorPortfolioItem.last.title).to eq("Kitchen remodel")
    end
  end
end
