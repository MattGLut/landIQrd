# frozen_string_literal: true

class ContractorPortfolioItemPolicy < ApplicationPolicy
  def index?
    user.contractor?
  end

  def create?
    user.contractor?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.contractor?
        scope.where(contractor_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def owner?
    user.contractor? && record.contractor_id == user.id
  end
end
