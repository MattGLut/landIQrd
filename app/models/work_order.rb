class WorkOrder < ApplicationRecord
  belongs_to :unit
  belongs_to :lease, optional: true
  belongs_to :created_by, class_name: "User", inverse_of: :created_work_orders

  has_many :work_order_assignments, dependent: :destroy
  has_many :contractors, through: :work_order_assignments, source: :contractor
  has_one :conversation, dependent: :nullify

  has_many_attached :photos

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true
  enum :status, { open: 0, in_progress: 1, on_hold: 2, completed: 3, cancelled: 4 }, prefix: true

  validates :title, presence: true

  scope :active, -> { where.not(status: %i[completed cancelled]) }

  scope :for_landlord, ->(user) {
    joins(unit: :property).where(properties: { landlord_id: user.id })
  }

  scope :for_contractor, ->(user) {
    joins(:work_order_assignments).where(work_order_assignments: { contractor_id: user.id })
  }

  scope :for_tenant, ->(user) {
    leased_unit_ids = Unit.joins(:leases).where(leases: { tenant_id: user.id }).select(:id)
    where(created_by_id: user.id).or(where(unit_id: leased_unit_ids))
  }

  delegate :property, to: :unit
  delegate :landlord, to: :unit

  def status_color
    {
      "open" => :blue,
      "in_progress" => :yellow,
      "on_hold" => :gray,
      "completed" => :green,
      "cancelled" => :red
    }.fetch(status, :gray)
  end

  def priority_color
    {
      "low" => :gray,
      "medium" => :blue,
      "high" => :yellow,
      "urgent" => :red
    }.fetch(priority, :gray)
  end
end
