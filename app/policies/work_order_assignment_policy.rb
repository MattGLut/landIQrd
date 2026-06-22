# frozen_string_literal: true

class WorkOrderAssignmentPolicy < ApplicationPolicy
  # Landlords/admins create and remove assignments.
  def create?
    manage?
  end

  def destroy?
    manage?
  end

  # The assigned contractor (or a manager) can update assignment status.
  def update?
    manage? || record.contractor_id == user.id
  end

  private

  def manage?
    user.admin? || record.work_order.unit.property.landlord_id == user.id
  end
end
