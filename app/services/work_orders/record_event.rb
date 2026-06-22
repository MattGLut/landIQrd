module WorkOrders
  class RecordEvent
    def self.call(work_order:, user:, action:, metadata: {})
      work_order.work_order_events.create!(user: user, action: action, metadata: metadata)
    end
  end
end
