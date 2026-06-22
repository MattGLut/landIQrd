# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    user.admin? || record.conversation.conversation_participants.exists?(user_id: user.id)
  end
end
