class Lease < ApplicationRecord
  belongs_to :unit
  belongs_to :tenant, class_name: "User", inverse_of: :leases

  has_many :work_orders, dependent: :nullify
  has_one :lease_invitation, dependent: :nullify

  has_many_attached :documents

  enum :status, { draft: 0, active: 1, ended: 2, terminated: 3 }

  validates :start_date, presence: true
  validates :rent_amount, :deposit_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :end_after_start
  validate :one_active_lease_per_unit, if: :active?

  scope :expiring_within, ->(days) {
    where(status: :active).where.not(end_date: nil).where(end_date: Date.current..(Date.current + days.days))
  }

  EXPIRING_SOON_DAYS = 90

  delegate :property, to: :unit
  delegate :landlord, to: :unit

  def expiring_soon?(days = EXPIRING_SOON_DAYS)
    return false unless active? && end_date.present?

    end_date.between?(Date.current, Date.current + days.days)
  end

  def term_description
    finish = end_date ? end_date.to_fs(:long) : "open-ended"
    "#{start_date.to_fs(:long)} - #{finish}"
  end

  private

  def end_after_start
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end

  def one_active_lease_per_unit
    return if unit_id.blank?

    conflict = unit.leases.where(status: :active).where.not(id: id)
    errors.add(:unit, "already has an active lease") if conflict.exists?
  end
end
