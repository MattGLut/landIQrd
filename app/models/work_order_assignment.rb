class WorkOrderAssignment < ApplicationRecord
  belongs_to :work_order
  belongs_to :contractor, class_name: "User", inverse_of: :work_order_assignments

  enum :status, { pending: 0, accepted: 1, declined: 2, completed: 3 }, prefix: true

  validates :contractor_id, uniqueness: { scope: :work_order_id }
  validate :contractor_must_be_contractor

  def status_color
    {
      "pending" => :yellow,
      "accepted" => :blue,
      "declined" => :red,
      "completed" => :green
    }.fetch(status, :gray)
  end

  after_commit :sync_conversation_and_notify, on: :create
  after_commit :notify_response, on: :update
  after_commit :resync_conversation, on: :destroy

  private

  def contractor_must_be_contractor
    return if contractor.nil?

    errors.add(:contractor, "must be a contractor") unless contractor.contractor?
  end

  def sync_conversation_and_notify
    Conversation.for_work_order!(work_order)
    Notifications::Deliver.contractor_assigned(self, actor: nil)
  end

  def resync_conversation
    work_order.conversation&.sync_work_order_participants!
  end

  def notify_response
    return unless saved_change_to_status?
    return unless status_accepted? || status_declined?

    Notifications::Deliver.assignment_responded(self, actor: contractor)
  end
end
