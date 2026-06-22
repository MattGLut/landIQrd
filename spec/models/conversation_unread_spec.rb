require "rails_helper"

RSpec.describe "Conversation unread tracking", type: :model do
  let(:tenant) { create(:tenant) }
  let(:landlord) { create(:landlord) }
  let(:conversation) { Conversation.direct_between!(tenant, landlord) }
  let(:participant) { conversation.conversation_participants.find_by!(user: tenant) }

  describe ConversationParticipant do
    describe "#mark_read!" do
      it "sets last_read_at" do
        expect { participant.mark_read! }.to change(participant, :last_read_at).from(nil)
      end
    end
  end

  describe Conversation do
    describe "#unread_for?" do
      it "is true when another participant posted after last read" do
        conversation.messages.create!(author: landlord, body: "Hello")
        expect(conversation.unread_for?(tenant)).to be(true)
      end

      it "is false after marking read" do
        conversation.messages.create!(author: landlord, body: "Hello")
        participant.mark_read!
        expect(conversation.unread_for?(tenant)).to be(false)
      end

      it "ignores the user's own messages" do
        conversation.messages.create!(author: tenant, body: "My note")
        expect(conversation.unread_for?(tenant)).to be(false)
      end
    end
  end
end
