# frozen_string_literal: true

class ContractorPolicy < ApplicationPolicy
  def index?
    user.landlord? || user.admin?
  end

  def show?
    (user.landlord? || user.admin?) && record.contractor?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.landlord? || user.admin?
        scope.contractor.order(:last_name, :first_name)
      else
        scope.none
      end
    end
  end
end
