# frozen_string_literal: true

class WalkthroughBookingPolicy < ApplicationPolicy
  def index?
    user.contractor?
  end

  # `record` is a WalkthroughBooking built for a slot.
  def create?
    user.contractor? && JobPolicy.new(user, record.job).bid?
  end

  def destroy?
    record.contractor_id == user.id && record.confirmed? && !record.walkthrough_slot.past?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.contractor?
        scope.where(contractor_id: user.id)
      elsif user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
