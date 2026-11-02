# A one-step work order for a contractor the landlord already works with.
# Persisted as a WorkOrder plus an accepted assignment (see WorkOrders::QuickAssign).
class QuickJob
  include ActiveModel::Model

  attr_accessor :contractor_id, :unit_id, :title, :description, :category, :priority,
                :scheduled_at, :price, :photos

  validates :contractor_id, :unit_id, :title, presence: true
  validates :title, length: { maximum: 150 }
  validates :description, length: { maximum: 2000 }
  validates :category, inclusion: { in: WorkOrder.categories.keys }
  validates :priority, inclusion: { in: WorkOrder.priorities.keys }
  validate :price_is_positive, if: -> { price.present? }

  def initialize(attributes = {})
    super
    self.category = "general" if category.blank?
    self.priority = "medium" if priority.blank?
  end

  def price_cents
    return if price.blank?

    cleaned = price.to_s.delete("$, ")
    (BigDecimal(cleaned) * 100).round.to_i
  rescue ArgumentError
    nil
  end

  def attached_photos
    Array(photos).compact_blank
  end

  private

  def price_is_positive
    cents = price_cents
    return if cents&.positive?

    errors.add(:price, "must be a positive amount")
  end
end
