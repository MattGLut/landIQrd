class WorkOrder < ApplicationRecord
  include AASM

  class InvalidTransition < StandardError; end

  belongs_to :unit
  belongs_to :lease, optional: true
  belongs_to :created_by, class_name: "User", inverse_of: :created_work_orders
  belongs_to :closed_by, class_name: "User", optional: true

  has_many :work_order_assignments, dependent: :destroy
  has_many :contractors, through: :work_order_assignments, source: :contractor
  has_many :work_order_events, dependent: :destroy
  has_one :conversation, dependent: :nullify

  has_many_attached :photos

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true
  enum :status, {
    open: 0,
    pending_tenant: 1,
    pending_management: 2,
    on_hold: 3,
    completed: 4,
    cancelled: 5
  }, prefix: true
  enum :category, {
    plumbing: "plumbing",
    electrical: "electrical",
    hvac: "hvac",
    appliance: "appliance",
    pest: "pest",
    general: "general",
    other: "other"
  }, prefix: true

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

  after_create :log_created_event

  delegate :property, to: :unit
  delegate :landlord, to: :unit

  attr_accessor :transition_user, :transition_closure_reason, :transition_from_status

  aasm column: :status, enum: true do
    state :open, initial: true
    state :pending_tenant, :pending_management, :on_hold, :completed, :cancelled

    event :await_management do
      transitions from: %i[open pending_tenant on_hold], to: :pending_management
      after { log_status_transition! }
    end

    event :await_tenant do
      transitions from: %i[open pending_management on_hold], to: :pending_tenant
      after { log_status_transition! }
    end

    event :hold do
      transitions from: %i[open pending_management pending_tenant], to: :on_hold
      after { log_status_transition! }
    end

    event :complete do
      transitions from: %i[pending_management pending_tenant on_hold], to: :completed
      after { log_status_transition! }
    end

    event :reopen do
      transitions from: :completed, to: :pending_management
      after { log_status_transition! }
    end

    event :cancel do
      transitions from: %i[open pending_tenant pending_management on_hold], to: :cancelled
      before { apply_cancellation_fields!(required_reason: false) }
      after { log_cancellation!(action: "cancelled") }
    end

    event :close do
      transitions from: %i[open pending_tenant pending_management on_hold], to: :cancelled
      before { apply_cancellation_fields!(required_reason: true) }
      after { log_cancellation!(action: "closed") }
    end
  end

  def active?
    !status_completed? && !status_cancelled?
  end

  def status_color
    {
      "open" => :blue,
      "pending_management" => :yellow,
      "pending_tenant" => :indigo,
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

  def transition_to!(target_status, user:, closure_reason: nil)
    target = target_status.to_sym
    transition = aasm.permitted_transitions.find { |entry| entry[:state] == target }
    raise InvalidTransition, "Cannot move from #{status} to #{target_status}" unless transition

    self.transition_user = user
    self.transition_closure_reason = closure_reason
    self.transition_from_status = status

    if target == :cancelled
      cancel!
    else
      public_send(:"#{transition[:event]}!")
    end
  rescue AASM::InvalidTransition => e
    raise InvalidTransition, e.message
  end

  def close_with_reason!(user:, closure_reason:)
    reason = closure_reason.to_s.strip
    raise InvalidTransition, "Closure reason is required" if reason.blank?
    raise InvalidTransition, "Work order is already closed" unless active?

    self.transition_user = user
    self.transition_closure_reason = reason
    self.transition_from_status = status
    close!
  rescue AASM::InvalidTransition => e
    raise InvalidTransition, e.message
  end

  private

  def log_created_event
    WorkOrders::RecordEvent.call(work_order: self, user: created_by, action: "created")
  end

  def apply_cancellation_fields!(required_reason:)
    reason = transition_closure_reason.to_s.strip
    raise InvalidTransition, "Closure reason is required" if required_reason && reason.blank?

    self.closure_reason = reason if reason.present?
    self.closed_by = transition_user
    self.closed_at = Time.current
  end

  def log_status_transition!
    WorkOrders::RecordEvent.call(
      work_order: self,
      user: transition_user,
      action: "status_changed",
      metadata: {
        "from" => transition_from_status,
        "to" => status
      }
    )
    Notifications::Deliver.work_order_status_changed(self, actor: transition_user)
  end

  def log_cancellation!(action:)
    WorkOrders::RecordEvent.call(
      work_order: self,
      user: transition_user,
      action: action,
      metadata: {
        "from" => transition_from_status,
        "to" => "cancelled",
        "closure_reason" => closure_reason
      }.compact
    )
    Notifications::Deliver.work_order_status_changed(self, actor: transition_user)
  end
end
