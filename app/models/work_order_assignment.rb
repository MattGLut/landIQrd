class WorkOrderAssignment < ApplicationRecord
  belongs_to :work_order
  belongs_to :contractor, class_name: "User", inverse_of: :work_order_assignments

  enum :status, { pending: 0, accepted: 1, declined: 2, completed: 3 }, prefix: true

  validates :contractor_id, uniqueness: { scope: :work_order_id }
  validate :contractor_must_be_contractor

  private

  def contractor_must_be_contractor
    return if contractor.nil?

    errors.add(:contractor, "must be a contractor") unless contractor.contractor?
  end
end
