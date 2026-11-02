# frozen_string_literal: true

class ContractorRelationshipPolicy < ApplicationPolicy
  def index?
    user.contractor?
  end

  def create?
    user.landlord? && record.landlord_id == user.id
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def accept?
    contractor_party? && record.status_pending?
  end

  def decline?
    accept?
  end

  def request_again?
    user.landlord? && record.landlord_id == user.id && record.status_declined?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.contractor?
        scope.where(contractor_id: user.id)
      elsif user.landlord?
        scope.where(landlord_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def contractor_party?
    user.contractor? && record.contractor_id == user.id
  end
end
