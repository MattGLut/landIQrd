# frozen_string_literal: true

class WorkOrderPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || landlord_owner? || creator? || assigned_contractor? || tenant_on_unit?
  end

  def create?
    user.tenant? || user.landlord? || user.admin?
  end

  def update?
    edit_details? || change_status?
  end

  def edit?
    edit_details? || change_status?
  end

  def edit_details?
    return false unless record.active?

    user.admin? || landlord_owner? || creator?
  end

  def change_status?
    user.admin? || landlord_owner?
  end

  def destroy?
    user.admin?
  end

  def close?
    record.active? && (creator? || landlord_owner? || user.admin?)
  end

  def schedule?
    user.landlord? || user.contractor? || user.admin?
  end

  # Only landlords/admins manage contractor assignments.
  def assign?
    user.admin? || landlord_owner?
  end

  private

  def landlord_owner?
    record.unit.property.landlord_id == user.id
  end

  def creator?
    record.created_by_id == user.id
  end

  def assigned_contractor?
    record.work_order_assignments.any? { |a| a.contractor_id == user.id }
  end

  def tenant_on_unit?
    user.tenant? && record.unit.leases.exists?(tenant_id: user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.for_landlord(user)
      elsif user.contractor?
        scope.for_contractor(user)
      elsif user.tenant?
        scope.for_tenant(user)
      else
        scope.none
      end
    end
  end
end
