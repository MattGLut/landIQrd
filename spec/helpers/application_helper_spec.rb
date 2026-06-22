require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#unread_conversations_count" do
    it "counts conversations with unread messages from others" do
      tenant = create(:tenant)
      landlord = create(:landlord)
      unread = Conversation.direct_between!(tenant, landlord)
      read = Conversation.direct_between!(tenant, create(:landlord))
      unread.messages.create!(author: landlord, body: "New message")
      read.messages.create!(author: read.participants.find { |u| u.landlord? }, body: "Old")
      read.conversation_participants.find_by(user: tenant).mark_read!

      expect(helper.unread_conversations_count(tenant)).to eq(1)
    end
  end

  describe "#unread_badge" do
    it "returns nil for zero" do
      expect(helper.unread_badge(0)).to be_nil
    end

    it "renders a badge for positive counts" do
      expect(helper.unread_badge(3)).to include("3")
    end
  end
end
