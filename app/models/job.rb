# A request for proposals: a landlord describes work, picks trades, optionally
# publishes walkthrough slots, and contractors answer with priced proposals.
# Awarding a proposal creates a WorkOrder (see Jobs::Award).
class Job < ApplicationRecord
  include AttachmentValidation

  TIMEZONES = [
    "Eastern Time (US & Canada)",
    "Central Time (US & Canada)",
    "Mountain Time (US & Canada)",
    "Pacific Time (US & Canada)"
  ].freeze

  MAX_ATTACHMENT_SIZE = 25.megabytes
  ATTACHMENT_TYPES = (AttachmentValidation::IMAGE_TYPES + AttachmentValidation::DOCUMENT_TYPES).freeze

  belongs_to :property
  belongs_to :unit, optional: true
  belongs_to :created_by, class_name: "User", inverse_of: :created_jobs
  belongs_to :work_order, optional: true

  has_many :walkthrough_slots, -> { order(:starts_at) }, dependent: :destroy, inverse_of: :job
  has_many :walkthrough_bookings, through: :walkthrough_slots
  has_many :proposals, dependent: :destroy, inverse_of: :job

  has_many_attached :attachments

  enum :status, { draft: 0, open: 1, awarded: 2, closed: 3 }, prefix: true

  before_validation :normalize_trades

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 1000 }
  validates :timezone, inclusion: { in: TIMEZONES }
  validates :slot_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }
  validate :trades_are_known
  validate :unit_belongs_to_property
  validate :creator_can_post_for_property
  validates_attachments :attachments, content_types: ATTACHMENT_TYPES, max_size: MAX_ATTACHMENT_SIZE

  with_options on: :publish do
    validates :description, presence: true
    validates :proposal_deadline, presence: true
    validate :deadline_not_in_past
    validate :trades_present
    validate :walkthrough_slots_present_when_required
  end

  scope :recent, -> { order(created_at: :desc) }
  scope :for_landlord, ->(user) { joins(:property).where(properties: { landlord_id: user.id }) }
  scope :accepting_proposals, -> {
    status_open.where("jobs.proposal_deadline IS NULL OR jobs.proposal_deadline >= ?", Date.current)
  }
  scope :matching_trades, ->(trades) {
    keys = Array(trades).compact_blank
    keys.empty? ? none : where("jobs.trades && ARRAY[?]::varchar[]", keys)
  }

  delegate :landlord, to: :property

  def trade_labels
    trades.map { |key| WorkOrder.trade_label(key) }
  end

  def primary_trade
    trades.first
  end

  # Category used for the WorkOrder created on award; falls back to "general".
  def work_order_category
    key = trades.find { |trade| WorkOrder::CATEGORIES.key?(trade.to_sym) }
    key || "general"
  end

  def accepting_proposals?
    status_open? && (proposal_deadline.nil? || proposal_deadline >= Date.current)
  end

  def editable?
    status_draft? || status_open?
  end

  def walkthrough_available?
    walkthrough_slots.any?(&:available?)
  end

  def location_label
    [ property.name, property.city, property.state ].compact_blank.join(", ")
  end

  def publish!
    raise ActiveRecord::RecordInvalid, self unless valid?(:publish)

    update!(status: :open, published_at: Time.current)
  end

  def close!
    update!(status: :closed)
  end

  def booking_for(contractor)
    walkthrough_bookings.merge(WalkthroughBooking.confirmed).find_by(contractor_id: contractor.id)
  end

  def proposal_for(contractor)
    proposals.find_by(contractor_id: contractor.id)
  end

  private

  def normalize_trades
    self.trades = Array(trades).compact_blank.map(&:to_s).uniq
  end

  def trades_are_known
    unknown = trades - WorkOrderCategory::MARKETPLACE_TRADES
    errors.add(:trades, "include an unknown trade") if unknown.any?
  end

  def trades_present
    errors.add(:trades, "must include at least one trade") if trades.empty?
  end

  def deadline_not_in_past
    return if proposal_deadline.blank? || proposal_deadline >= Date.current

    errors.add(:proposal_deadline, "cannot be in the past")
  end

  def walkthrough_slots_present_when_required
    return unless walkthrough_required?
    return if walkthrough_slots.any?

    errors.add(:base, "Add at least one walkthrough time slot or turn off required walkthroughs")
  end

  def unit_belongs_to_property
    return if unit.blank? || property.blank?
    return if unit.property_id == property_id

    errors.add(:unit, "must belong to the selected property")
  end

  def creator_can_post_for_property
    return if created_by.blank? || property.blank?
    return if created_by.admin? || property.landlord_id == created_by_id

    errors.add(:property, "must be one of your properties")
  end
end
