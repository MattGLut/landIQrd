class Unit < ApplicationRecord
  belongs_to :property

  has_many :leases, dependent: :destroy
  has_many :work_orders, dependent: :destroy
  has_many :lease_invitations, dependent: :destroy

  validates :label, presence: true

  delegate :landlord, to: :property

  def full_label
    "#{property.name} · #{label}"
  end

  def current_tenant
    active_lease&.tenant
  end

  def active_lease
    leases.find_by(status: :active)
  end
end
