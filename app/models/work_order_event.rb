class WorkOrderEvent < ApplicationRecord
  belongs_to :work_order
  belongs_to :user, optional: true

  ACTIONS = %w[created updated status_changed closed cancelled].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :chronological, -> { order(created_at: :asc) }

  def description
    case action
    when "created"
      "#{actor_label} submitted this request."
    when "updated"
      describe_changes
    when "status_changed"
      from = metadata["from"]&.humanize
      to = metadata["to"]&.humanize
      "#{actor_label} changed status from #{from} to #{to}."
    when "closed"
      "#{actor_label} closed this request: #{metadata['closure_reason']}"
    when "cancelled"
      reason = metadata["closure_reason"].presence
      base = "#{actor_label} cancelled this request."
      reason ? "#{base} Reason: #{reason}" : base
    else
      action.humanize
    end
  end

  private

  def actor_label
    user&.display_name || "System"
  end

  def describe_changes
    changes = metadata.fetch("changes", {})
    return "#{actor_label} updated this request." if changes.blank?

    parts = changes.map { |field, values| "#{field.humanize}: #{values[0].inspect} → #{values[1].inspect}" }
    "#{actor_label} updated #{parts.to_sentence}."
  end
end
