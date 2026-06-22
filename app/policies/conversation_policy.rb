# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || participant?
  end

  def create?
    user.admin? || user.tenant? || user.landlord? || user.contractor?
  end

  private

  def participant?
    record.conversation_participants.any? { |p| p.user_id == user.id }
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:conversation_participants)
             .where(conversation_participants: { user_id: user.id })
      end
    end
  end
end
