# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  def show?
    manage?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  private

  def manage?
    user.admin? || record.property.landlord_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.joins(:property).where(properties: { landlord_id: user.id })
      else
        scope.none
      end
    end
  end
end
