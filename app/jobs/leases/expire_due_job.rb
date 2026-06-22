class Leases::ExpireDueJob < ApplicationJob
  queue_as :default

  def perform
    Lease.where(status: :active).where(end_date: ...Date.current).find_each do |lease|
      lease.update!(status: :ended)
      Notifications::Deliver.lease_expiring(lease)
    end
  end
end
