# frozen_string_literal: true

class LeasePolicy < ApplicationPolicy
  def show?
    user.admin? || landlord_owner? || tenant_party?
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
    user.admin? || landlord_owner?
  end

  def landlord_owner?
    record.unit.property.landlord_id == user.id
  end

  def tenant_party?
    record.tenant_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.joins(unit: :property).where(properties: { landlord_id: user.id })
      elsif user.tenant?
        scope.where(tenant_id: user.id)
      else
        scope.none
      end
    end
  end
end
