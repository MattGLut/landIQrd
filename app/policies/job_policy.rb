# frozen_string_literal: true

class JobPolicy < ApplicationPolicy
  def index?
    user.landlord? || user.admin?
  end

  def show?
    user.admin? || owner? || contractor_can_view?
  end

  # "Find work" listing for contractors.
  def browse?
    user.contractor?
  end

  def create?
    user.landlord? || user.admin?
  end

  def update?
    (user.admin? || owner?) && record.editable?
  end

  def publish?
    (user.admin? || owner?) && record.status_draft?
  end

  def close?
    (user.admin? || owner?) && record.status_open?
  end

  def destroy?
    (user.admin? || owner?) && record.status_draft?
  end

  def manage?
    user.admin? || owner?
  end

  def view_proposals?
    manage?
  end

  def bid?
    user.contractor? && matches_trades? && record.accepting_proposals?
  end

  private

  def owner?
    record.property.landlord_id == user.id
  end

  def matches_trades?
    (user.trades & record.trades).any?
  end

  def contractor_can_view?
    return false unless user.contractor?
    return false if record.status_draft?

    matches_trades? || record.proposals.exists?(contractor_id: user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.for_landlord(user)
      elsif user.contractor?
        visible_to_contractor
      else
        scope.none
      end
    end

    private

    def visible_to_contractor
      own_job_ids = Proposal.where(contractor_id: user.id).select(:job_id)
      base = scope.where.not(status: Job.statuses[:draft])

      if user.trades.any?
        base.where("jobs.trades && ARRAY[?]::varchar[] OR jobs.id IN (?)", user.trades, own_job_ids)
      else
        base.where(id: own_job_ids)
      end
    end
  end
end
