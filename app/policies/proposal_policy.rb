# frozen_string_literal: true

class ProposalPolicy < ApplicationPolicy
  def index?
    user.landlord? || user.contractor? || user.admin?
  end

  def show?
    user.admin? || job_owner? || own_proposal?
  end

  # `record` may be a new Proposal built for a job.
  def create?
    user.contractor? && JobPolicy.new(user, record.job).bid?
  end

  def update?
    own_proposal? && record.editable?
  end

  def withdraw?
    own_proposal? && record.submitted?
  end

  def award?
    (user.admin? || job_owner?) && record.submitted? && record.job.status_open?
  end

  private

  def own_proposal?
    record.contractor_id == user.id
  end

  def job_owner?
    record.job.property.landlord_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.landlord?
        scope.joins(job: :property).where(properties: { landlord_id: user.id })
      elsif user.contractor?
        scope.where(contractor_id: user.id)
      else
        scope.none
      end
    end
  end
end
