module WorkOrders
  class Closer
    class Error < StandardError; end

    def self.call(work_order, user:, closure_reason:)
      new(work_order, user:, closure_reason:).call
    end

    def initialize(work_order, user:, closure_reason:)
      @work_order = work_order
      @user = user
      @closure_reason = closure_reason.to_s.strip
    end

    def call
      raise Error, "Closure reason is required" if closure_reason.blank?
      raise Error, "Work order is already closed" unless work_order.active?

      from = work_order.status
      work_order.update!(
        status: :cancelled,
        closure_reason: closure_reason,
        closed_by: user,
        closed_at: Time.current
      )
      RecordEvent.call(
        work_order: work_order,
        user: user,
        action: "closed",
        metadata: { "from" => from, "to" => "cancelled", "closure_reason" => closure_reason }
      )
      Notifications::Deliver.work_order_status_changed(work_order, actor: user)
      work_order
    end

    private

    attr_reader :work_order, :user, :closure_reason
  end
end
