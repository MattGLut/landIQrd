class WalkthroughSlot < ApplicationRecord
  belongs_to :job, inverse_of: :walkthrough_slots
  has_many :walkthrough_bookings, dependent: :destroy

  validates :starts_at, :ends_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }
  validates :starts_at, uniqueness: { scope: :job_id, message: "already has a slot at that time" }
  validate :ends_after_start
  validate :starts_in_future, on: :create

  scope :upcoming, -> { where("walkthrough_slots.starts_at > ?", Time.current) }
  scope :chronological, -> { order(:starts_at) }

  def confirmed_bookings_count
    walkthrough_bookings.confirmed.count
  end

  def remaining
    [ capacity - confirmed_bookings_count, 0 ].max
  end

  def full?
    remaining.zero?
  end

  def past?
    starts_at <= Time.current
  end

  def available?
    !past? && !full?
  end

  def time_range_label
    zone = ActiveSupport::TimeZone[job.timezone] || Time.zone
    start_time = starts_at.in_time_zone(zone)
    end_time = ends_at.in_time_zone(zone)
    "#{start_time.strftime("%-l:%M %p")} - #{end_time.strftime("%-l:%M %p")}"
  end

  def day_label
    zone = ActiveSupport::TimeZone[job.timezone] || Time.zone
    starts_at.in_time_zone(zone).strftime("%a, %b %-d")
  end

  private

  def starts_in_future
    return if starts_at.blank? || starts_at > Time.current

    errors.add(:starts_at, "must be in the future")
  end

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "must be after the start time")
  end
end
