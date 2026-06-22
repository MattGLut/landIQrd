require "rails_helper"

RSpec.describe ConversationParticipant, type: :model do
  it { is_expected.to belong_to(:conversation) }
  it { is_expected.to belong_to(:user) }

  it "requires a user to appear only once in a conversation" do
    conversation = create(:conversation)
    user = create(:tenant)
    conversation.conversation_participants.create!(user: user)

    duplicate = conversation.conversation_participants.build(user: user)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end
end
