require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }

  describe "visibility" do
    it "hides a direct tenant-landlord thread from a contractor" do
      conversation = Conversation.direct_between!(tenant, landlord)
      sign_in contractor
      get conversation_path(conversation)
      expect(response).to redirect_to(root_path)
    end

    it "shows a work-order thread to its assigned contractor" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      create(:work_order_assignment, work_order: work_order, contractor: contractor)
      work_order.reload
      conversation = Conversation.for_work_order!(work_order)

      sign_in contractor
      get conversation_path(conversation)
      expect(response).to have_http_status(:ok)
    end

    it "hides a work-order thread from an unassigned contractor" do
      work_order = create(:work_order, unit: unit, created_by: tenant)
      conversation = Conversation.for_work_order!(work_order)

      sign_in contractor
      get conversation_path(conversation)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /conversations" do
    it "only lists threads the user participates in" do
      mine = Conversation.direct_between!(tenant, landlord)
      mine.messages.create!(author: tenant, body: "Mine secret message")
      theirs = Conversation.direct_between!(create(:tenant), create(:landlord))
      theirs.messages.create!(author: theirs.participants.first, body: "Other secret message")

      sign_in tenant
      get conversations_path
      expect(response.body).to include("Mine secret message")
      expect(response.body).not_to include("Other secret message")
    end
  end

  describe "POST /conversations" do
    it "starts a direct thread between two users" do
      sign_in tenant
      post conversations_path, params: { recipient_id: landlord.id }
      expect(response).to redirect_to(Conversation.last)
    end

    it "redirects when no recipient or work order is provided" do
      sign_in tenant
      post conversations_path
      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to eq("Could not start that conversation.")
    end
  end

  describe "POST /conversations/:id/messages" do
    it "lets a participant post a message" do
      conversation = Conversation.direct_between!(tenant, landlord)
      sign_in tenant
      expect {
        post conversation_messages_path(conversation), params: { message: { body: "Hi" } }
      }.to change(conversation.messages, :count).by(1)
    end

    it "forbids a non-participant from posting" do
      conversation = Conversation.direct_between!(tenant, landlord)
      sign_in contractor
      post conversation_messages_path(conversation), params: { message: { body: "Sneaky" } }
      expect(conversation.messages.count).to eq(0)
    end

    it "rejects an empty message without attachments" do
      conversation = Conversation.direct_between!(tenant, landlord)
      sign_in tenant
      post conversation_messages_path(conversation), params: { message: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(conversation.messages.count).to eq(0)
    end
  end
end
