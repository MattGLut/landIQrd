class Conversation < ApplicationRecord
  belongs_to :work_order, optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  # Finds (or creates) the single thread tied to a work order and keeps its
  # participant list in sync with the people involved in that work order.
  def self.for_work_order!(work_order)
    conversation = find_or_create_by!(work_order: work_order) do |c|
      c.subject = "Work order: #{work_order.title}"
    end
    conversation.sync_work_order_participants!
    conversation
  end

  # Finds (or creates) a direct, work-order-less thread between two users.
  def self.direct_between!(user_a, user_b)
    ids = [ user_a.id, user_b.id ].uniq.sort
    existing = where(work_order_id: nil).detect { |c| c.participant_ids.sort == ids }
    return existing if existing

    conversation = create!(subject: "Direct message")
    ids.each { |id| conversation.conversation_participants.create!(user_id: id) }
    conversation
  end

  def sync_work_order_participants!
    return unless work_order

    desired = [ work_order.created_by, work_order.unit.property.landlord, *work_order.contractors ].compact.uniq
    desired.each { |user| conversation_participants.find_or_create_by!(user: user) }
  end

  def title
    subject.presence || "Conversation"
  end

  def latest_message
    messages.order(:created_at).last
  end
end
