class WalkthroughBooking < ApplicationRecord
  belongs_to :walkthrough_slot
  belongs_to :contractor, class_name: "User", inverse_of: :walkthrough_bookings

  enum :status, { confirmed: 0, cancelled: 1 }

  validates :contractor_id, uniqueness: { scope: :walkthrough_slot_id }
  validate :contractor_must_be_contractor
  validate :job_must_accept_bookings, on: :create
  validate :slot_must_have_room, on: :create
  validate :one_booking_per_job, on: :create

  delegate :job, to: :walkthrough_slot

  scope :upcoming, -> { joins(:walkthrough_slot).merge(WalkthroughSlot.upcoming) }

  def cancel!
    update!(status: :cancelled)
  end

  private

  def contractor_must_be_contractor
    return if contractor.nil?

    errors.add(:contractor, "must be a contractor") unless contractor.contractor?
  end

  def job_must_accept_bookings
    return if walkthrough_slot.blank?
    return if job.accepting_proposals?

    errors.add(:base, "This job is no longer accepting walkthroughs")
  end

  def slot_must_have_room
    return if walkthrough_slot.blank?

    if walkthrough_slot.past?
      errors.add(:base, "That time has already passed")
    elsif walkthrough_slot.full?
      errors.add(:base, "That time slot is already booked")
    end
  end

  def one_booking_per_job
    return if walkthrough_slot.blank? || contractor.blank?
    return unless job.booking_for(contractor)

    errors.add(:base, "You already have a walkthrough booked for this job")
  end
end
