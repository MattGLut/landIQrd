# frozen_string_literal: true

class WalkthroughSlotPolicy < ApplicationPolicy
  def create?
    (user.admin? || owner?) && record.job.editable?
  end

  def destroy?
    create?
  end

  private

  def owner?
    record.job.property.landlord_id == user.id
  end
end
