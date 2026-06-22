module WorkOrders
  class TransitionStatus
    TRANSITIONS = {
      "open" => %w[in_progress on_hold cancelled],
      "in_progress" => %w[on_hold completed cancelled],
      "on_hold" => %w[in_progress cancelled],
      "completed" => [],
      "cancelled" => []
    }.freeze

    class InvalidTransition < StandardError; end

    def self.call(work_order:, to:, user:, closure_reason: nil)
      new(work_order:, to:, user:, closure_reason:).call
    end

    def initialize(work_order:, to:, user:, closure_reason: nil)
      @work_order = work_order
      @to = to.to_s
      @user = user
      @closure_reason = closure_reason
    end

    def call
      validate_transition!
      from = work_order.status

      work_order.status = to
      if to == "cancelled"
        work_order.closure_reason = closure_reason if closure_reason.present?
        work_order.closed_by = user
        work_order.closed_at = Time.current
      end

      work_order.save!
      action = to == "cancelled" ? "cancelled" : "status_changed"
      RecordEvent.call(
        work_order: work_order,
        user: user,
        action: action,
        metadata: { "from" => from, "to" => to, "closure_reason" => closure_reason }.compact
      )
      Notifications::Deliver.work_order_status_changed(work_order, actor: user)
      work_order
    end

    private

    attr_reader :work_order, :to, :user, :closure_reason

    def validate_transition!
      allowed = TRANSITIONS.fetch(work_order.status, [])
      raise InvalidTransition, "Cannot move from #{work_order.status} to #{to}" unless allowed.include?(to)
    end
  end
end
