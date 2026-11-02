class Proposal < ApplicationRecord
  include AttachmentValidation

  DURATION_OPTIONS = {
    "1 day" => 1,
    "2 days" => 2,
    "3 days" => 3,
    "1 week" => 7,
    "2 weeks" => 14,
    "1 month" => 30,
    "2+ months" => 60
  }.freeze

  belongs_to :job, inverse_of: :proposals
  belongs_to :contractor, class_name: "User", inverse_of: :proposals
  has_one :work_order, dependent: :nullify

  has_many_attached :attachments

  enum :status, { submitted: 0, awarded: 1, declined: 2, withdrawn: 3 }

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :scope, presence: true, length: { maximum: 500 }
  validates :exclusions, length: { maximum: 500 }
  validates :earliest_start, presence: true
  validates :estimated_duration_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :contractor_id, uniqueness: { scope: :job_id, message: "has already submitted a proposal for this job" }
  validate :contractor_must_be_contractor
  validate :job_must_accept_proposals, on: :create
  validate :walkthrough_must_be_booked, on: :create
  validates_attachments :attachments, content_types: Job::ATTACHMENT_TYPES, max_size: Job::MAX_ATTACHMENT_SIZE

  scope :active, -> { where(status: %i[submitted awarded]) }
  scope :cheapest_first, -> { order(:amount_cents, :created_at) }

  delegate :property, to: :job

  # Dollar amount helper for forms ("2,450" or "2450.50" -> cents).
  def amount
    amount_cents && amount_cents / 100.0
  end

  def amount=(value)
    cleaned = value.to_s.delete("$, ")
    self.amount_cents = cleaned.blank? ? nil : (BigDecimal(cleaned) * 100).round.to_i
  rescue ArgumentError
    self.amount_cents = nil
  end

  def editable?
    submitted? && job.accepting_proposals?
  end

  def duration_label
    DURATION_OPTIONS.key(estimated_duration_days) || "#{estimated_duration_days} days"
  end

  def withdraw!
    raise ActiveRecord::RecordInvalid, self unless submitted?

    update!(status: :withdrawn)
  end

  private

  def contractor_must_be_contractor
    return if contractor.nil?

    errors.add(:contractor, "must be a contractor") unless contractor.contractor?
  end

  def job_must_accept_proposals
    return if job.blank?
    return if job.accepting_proposals?

    errors.add(:base, "This job is no longer accepting proposals")
  end

  def walkthrough_must_be_booked
    return if job.blank? || contractor.blank?
    return unless job.walkthrough_required?
    return if job.booking_for(contractor)

    errors.add(:base, "Book a walkthrough before submitting a proposal for this job")
  end
end
