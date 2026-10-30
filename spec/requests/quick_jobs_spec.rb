require "rails_helper"

RSpec.describe "Quick jobs", type: :request do
  let(:landlord) { create(:landlord) }
  let(:contractor) { create(:contractor, company_name: "FixIt Co") }
  let(:property) { create(:property, landlord: landlord, name: "Maple Court") }
  let(:unit) { create(:unit, property: property, label: "Apt 1A") }

  def save_contact(kind: "business")
    post contractor_relationships_path, params: {
      contractor_relationship: { contractor_id: contractor.id, kind: kind }
    }
  end

  describe "contacts" do
    it "lets a landlord save, update, and remove a contractor contact" do
      sign_in landlord

      expect { save_contact }.to change(ContractorRelationship, :count).by(1)
      relationship = ContractorRelationship.last
      expect(relationship).to be_kind_business
      expect(relationship).to be_status_pending
      expect(response).to redirect_to(contractor_path(contractor))

      patch contractor_relationship_path(relationship), params: {
        contractor_relationship: { kind: "personal" }
      }
      expect(relationship.reload).to be_kind_personal

      expect { delete contractor_relationship_path(relationship) }
        .to change(ContractorRelationship, :count).by(-1)
    end

    it "does not save the same contractor twice" do
      sign_in landlord
      save_contact
      save_contact

      expect(response).to redirect_to(contractor_path(contractor))
      follow_redirect!
      expect(response.body).to include("already saved as a contact")
      expect(ContractorRelationship.count).to eq(1)
    end

    it "forbids tenants" do
      sign_in create(:tenant)
      save_contact
      expect(response).to redirect_to(root_path)
      expect(ContractorRelationship.count).to eq(0)
    end

    it "lets the contractor accept or decline the request" do
      relationship = ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :business)
      sign_in contractor

      get contractor_relationships_path
      expect(response.body).to include(landlord.display_name)
      expect(response.body).to include("Awaiting acceptance")

      post accept_contractor_relationship_path(relationship)
      expect(relationship.reload).to be_status_accepted
      expect(response).to redirect_to(contractor_relationships_path)

      relationship.update!(status: :pending)
      post decline_contractor_relationship_path(relationship)
      expect(relationship.reload).to be_status_declined
    end

    it "does not let the landlord accept the request" do
      relationship = ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :personal)
      sign_in landlord

      post accept_contractor_relationship_path(relationship)
      expect(relationship.reload).to be_status_pending
    end
  end

  describe "GET /quick_jobs/new" do
    it "lists only contacts who have accepted" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :business, status: :accepted)
      waiting = create(:contractor, company_name: "Waiting Co")
      ContractorRelationship.create!(landlord: landlord, contractor: waiting, kind: :personal, status: :pending)
      outsider = create(:contractor, company_name: "Stranger Co")

      sign_in landlord
      get new_quick_job_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FixIt Co")
      expect(response.body).to include("Business contact")
      expect(response.body).not_to include("Waiting Co")
      expect(response.body).not_to include("Stranger Co")
    end

    it "explains the empty state when the landlord has no contacts" do
      sign_in landlord
      get new_quick_job_path

      expect(response.body).to include("No accepted contractors yet")
    end

    it "forbids tenants" do
      sign_in create(:tenant)
      get new_quick_job_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /quick_jobs" do
    it "assigns the job directly" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :personal, status: :accepted)
      sign_in landlord

      expect {
        post quick_jobs_path, params: {
          quick_job: {
            contractor_id: contractor.id,
            unit_id: unit.id,
            title: "Replace the faucet",
            description: "Kitchen sink faucet is loose.",
            category: "plumbing",
            priority: "high",
            price: "250"
          }
        }
      }.to change(WorkOrder, :count).by(1)

      work_order = WorkOrder.last
      expect(response).to redirect_to(work_order)
      expect(work_order.work_order_assignments.sole).to be_status_pending
      expect(work_order.price_cents).to eq(25_000)
      expect(Job.count).to eq(0)
    end

    it "rejects a contact who has not accepted yet" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :business, status: :pending)
      sign_in landlord

      expect {
        post quick_jobs_path, params: {
          quick_job: {
            contractor_id: contractor.id,
            unit_id: unit.id,
            title: "Replace the faucet",
            category: "plumbing",
            priority: "medium"
          }
        }
      }.not_to change(WorkOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("has not accepted")
    end

    it "lets the contractor accept the sent job" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :personal, status: :accepted)
      sign_in landlord
      post quick_jobs_path, params: {
        quick_job: {
          contractor_id: contractor.id,
          unit_id: unit.id,
          title: "Replace the faucet",
          category: "plumbing",
          priority: "high",
          price: "250"
        }
      }
      assignment = WorkOrder.last.work_order_assignments.sole

      sign_in contractor
      patch work_order_work_order_assignment_path(assignment.work_order, assignment),
            params: { work_order_assignment: { status: "accepted" } }

      expect(assignment.reload).to be_status_accepted
      expect(response).to redirect_to(assignment.work_order)
    end

    it "rejects a contractor who is not a contact" do
      sign_in landlord

      expect {
        post quick_jobs_path, params: {
          quick_job: {
            contractor_id: contractor.id,
            unit_id: unit.id,
            title: "Replace the faucet",
            category: "plumbing",
            priority: "medium"
          }
        }
      }.not_to change(WorkOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("personal or business contact")
    end

    it "rejects another landlord's unit" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :business, status: :accepted)
      other_unit = create(:unit)
      sign_in landlord

      post quick_jobs_path, params: {
        quick_job: {
          contractor_id: contractor.id,
          unit_id: other_unit.id,
          title: "Replace the faucet",
          category: "general",
          priority: "medium"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(WorkOrder.where(unit: other_unit)).to be_empty
    end
  end

  describe "GET /contractors" do
    it "filters to saved contractors" do
      ContractorRelationship.create!(landlord: landlord, contractor: contractor, kind: :business)
      create(:contractor, company_name: "Other Co")

      sign_in landlord
      get contractors_path, params: { relationship: "mine" }

      expect(response.body).to include("FixIt Co")
      expect(response.body).to include("Business contact")
      expect(response.body).not_to include("Other Co")
    end
  end
end
