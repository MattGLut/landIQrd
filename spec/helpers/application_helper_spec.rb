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

  describe "#nav_link_active?" do
    it "matches exact paths" do
      allow(helper).to receive(:request).and_return(double(path: "/work_orders"))
      expect(helper.nav_link_active?("/work_orders")).to be(true)
    end

    it "matches nested paths under the link" do
      allow(helper).to receive(:request).and_return(double(path: "/work_orders/1"))
      expect(helper.nav_link_active?("/work_orders")).to be(true)
    end

    it "excludes configured sibling paths from prefix matching" do
      allow(helper).to receive(:request).and_return(double(path: "/work_orders/schedule"))
      expect(helper.nav_link_active?("/work_orders", exclude_paths: [ "/work_orders/schedule" ])).to be(false)
      expect(helper.nav_link_active?("/work_orders/schedule")).to be(true)
    end

    it "accepts a single excluded path" do
      allow(helper).to receive(:request).and_return(double(path: "/work_orders/schedule"))
      expect(helper.nav_link_active?("/work_orders", exclude_paths: "/work_orders/schedule")).to be(false)
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
