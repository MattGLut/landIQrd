class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :author, class_name: "User", inverse_of: :messages

  has_many_attached :files

  validates :body, presence: true, unless: -> { files.attached? }

  after_create_commit :broadcast_to_conversation

  private

  def broadcast_to_conversation
    return if Thread.current[:suppress_realtime_broadcasts]

    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end
end
