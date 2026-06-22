require "rails_helper"

RSpec.describe "Conversations" do
  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let!(:lease) { create(:lease, unit: unit, tenant: tenant) }

  it "shows empty state when there are no conversations" do
    sign_in_and_visit(tenant, conversations_path)

    expect(page).to have_content("No conversations yet.")
    expect(page).to have_content("Select a conversation to view messages")
  end

  it "opens a work order conversation from the work order page" do
    work_order = create(:work_order, unit: unit, created_by: tenant, title: "Kitchen faucet")
    sign_in_and_visit(landlord, work_order_path(work_order))

    click_button "Open conversation"

    expect(page).to have_content("Work order")
    expect(page).to have_content("Kitchen faucet")
  end

  it "lists only conversations the user participates in" do
    mine = Conversation.direct_between!(tenant, landlord)
    mine.messages.create!(author: tenant, body: "Mine secret message")
    theirs = Conversation.direct_between!(create(:tenant), create(:landlord))
    theirs.messages.create!(author: theirs.participants.first, body: "Other secret message")

    sign_in_and_visit(tenant, conversations_path)

    expect(page).to have_content("Mine secret message")
    expect(page).not_to have_content("Other secret message")
  end

  it "denies non-participants from viewing a conversation" do
    conversation = Conversation.direct_between!(tenant, landlord)

    sign_in_and_visit(contractor, conversation_path(conversation))

    expect(page).to have_content("You are not authorized to perform that action.")
  end

  it "sends a message via HTML fallback" do
    conversation = Conversation.direct_between!(tenant, landlord)
    sign_in_and_visit(tenant, conversation_path(conversation))

    fill_in "Write a message...", with: "Hello landlord"
    click_button "Send"

    expect(page).to have_content("Hello landlord")
  end

  it "starts a direct conversation from a tenant lease as the tenant" do
    sign_in_and_visit(tenant, lease_path(lease))

    click_button "Message landlord"

    expect(page).to have_content("Direct message")
    expect(page).to have_content(landlord.display_name)
  end

  describe "Turbo Stream messaging", js: true do
    it "appends a message without a full page reload" do
      conversation = Conversation.direct_between!(tenant, landlord)
      sign_in_and_visit(tenant, conversation_path(conversation))

      expect(page).to have_content("No messages yet. Say hello.")

      fill_in "Write a message...", with: "Turbo hello"
      click_button "Send"

      expect(page).to have_content("Turbo hello")
      expect(page).not_to have_content("No messages yet. Say hello.")
      expect(page).to have_field("Write a message...", with: "")
    end
  end
end
