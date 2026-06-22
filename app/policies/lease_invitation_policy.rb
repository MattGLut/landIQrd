# frozen_string_literal: true

class LeaseInvitationPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user.landlord? && record.unit.property.landlord_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(unit: :property).where(properties: { landlord_id: user.id })
    end
  end
end
