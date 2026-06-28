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

    it "lets an admin browse contractors" do
      sign_in create(:admin)
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

    it "forbids contractors" do
      sign_in create(:contractor)
      get contractors_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /contractors/:id" do
    it "shows a contractor portfolio grouped by category" do
      create(:contractor_portfolio_item, contractor: contractor, title: "Hallway refresh", category: "general")

      sign_in landlord
      get contractor_path(contractor)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pipe repair")
      expect(response.body).to include("Hallway refresh")
      expect(response.body).to include("Plumbing")
      expect(response.body).to include("General")
      expect(response.body).to include(contractor.full_name)
      expect(response.body).to include("https://fixit.example.com")
    end

    it "forbids contractors from viewing the directory profile" do
      sign_in create(:contractor)
      get contractor_path(contractor)
      expect(response).to redirect_to(root_path)
    end
  end
end

RSpec.describe "Contractor portfolio", type: :request do
  let(:contractor) { create(:contractor) }
  let(:other_contractor) { create(:contractor) }

  describe "GET /contractor/business_profile/edit" do
    it "renders for the signed-in contractor" do
      sign_in contractor
      get edit_contractor_business_profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Business profile")
    end

    it "redirects non-contractors" do
      sign_in create(:landlord)
      get edit_contractor_business_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

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

    it "rejects an invalid website url" do
      sign_in contractor
      patch contractor_business_profile_path, params: {
        user: { website_url: "not-a-url" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(contractor.reload.website_url).to be_blank
    end
  end

  describe "GET /contractor/portfolio_items" do
    it "lists the contractor's portfolio items" do
      item = create(:contractor_portfolio_item, contractor: contractor, title: "Visible item")
      sign_in contractor
      get contractor_portfolio_items_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visible item")
      expect(response.body).not_to include(other_contractor.email)
    end

    it "forbids landlords" do
      sign_in create(:landlord)
      get contractor_portfolio_items_path
      expect(response).to redirect_to(root_path)
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

  describe "PATCH /contractor/portfolio_items/:id" do
    it "updates the contractor's own portfolio item" do
      item = create(:contractor_portfolio_item, contractor: contractor, title: "Old title")
      sign_in contractor

      patch contractor_portfolio_item_path(item), params: {
        contractor_portfolio_item: { title: "Updated title", description: "New details" }
      }

      expect(response).to redirect_to(contractor_portfolio_items_path)
      expect(item.reload.title).to eq("Updated title")
      expect(item.description).to eq("New details")
    end

    it "forbids updating another contractor's item" do
      item = create(:contractor_portfolio_item, contractor: other_contractor)
      sign_in contractor

      patch contractor_portfolio_item_path(item), params: {
        contractor_portfolio_item: { title: "Hijacked" }
      }

      expect(response).to have_http_status(:not_found)
      expect(item.reload.title).not_to eq("Hijacked")
    end
  end

  describe "DELETE /contractor/portfolio_items/:id" do
    it "destroys the contractor's own portfolio item" do
      item = create(:contractor_portfolio_item, contractor: contractor)
      sign_in contractor

      expect {
        delete contractor_portfolio_item_path(item)
      }.to change(ContractorPortfolioItem, :count).by(-1)

      expect(response).to redirect_to(contractor_portfolio_items_path)
    end
  end
end

RSpec.describe "Work order contractor picker", type: :request do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }
  let(:matching) { create(:contractor, company_name: "Pipe Pros") }
  let!(:other) { create(:contractor, company_name: "Random Co") }
  let!(:work_order) { create(:work_order, unit: unit, created_by: tenant, category: :plumbing, title: "Leaky pipe") }

  before do
    create(:contractor_portfolio_item, contractor: matching, category: "plumbing", title: "Pipe job")
  end

  it "shows all contractors by default with a relevant badge" do
    sign_in landlord
    get work_order_path(work_order)

    expect(response.body).to include("Pipe Pros")
    expect(response.body).to include("Random Co")
    expect(response.body).to include("1 relevant project")
  end

  it "filters to relevant contractors only" do
    sign_in landlord
    get work_order_path(work_order, contractor_filter: "relevant")

    expect(response.body).to include("Pipe Pros")
    expect(response.body).not_to include("Random Co")
  end
end
