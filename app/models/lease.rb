class Lease < ApplicationRecord
  belongs_to :unit
  belongs_to :tenant, class_name: "User", inverse_of: :leases

  has_many :work_orders, dependent: :nullify

  has_many_attached :documents

  enum :status, { draft: 0, active: 1, ended: 2, terminated: 3 }

  validates :start_date, presence: true
  validates :rent_amount, :deposit_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :end_after_start

  delegate :property, to: :unit
  delegate :landlord, to: :unit

  def term_description
    finish = end_date ? end_date.to_fs(:long) : "open-ended"
    "#{start_date.to_fs(:long)} - #{finish}"
  end

  private

  def end_after_start
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end
end
