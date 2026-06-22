class Unit < ApplicationRecord
  belongs_to :property
  has_many :leases, dependent: :destroy
  has_many :work_orders, dependent: :destroy

  validates :label, presence: true

  delegate :landlord, to: :property

  def full_label
    "#{property.name} - #{label}"
  end

  def active_lease
    leases.find(&:active?)
  end
end
