# frozen_string_literal: true

class QuickJobPolicy < ApplicationPolicy
  def new?
    user.landlord?
  end

  def create?
    user.landlord?
  end
end
