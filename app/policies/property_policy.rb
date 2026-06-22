# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  def index?
    user.landlord? || user.admin?
  end

  def show?
    owner_or_admin?
  end

  def create?
    user.landlord?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  private

  def owner_or_admin?
    user.admin? || record.landlord_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.where(landlord_id: user.id)
      else
        scope.none
      end
    end
  end
end
