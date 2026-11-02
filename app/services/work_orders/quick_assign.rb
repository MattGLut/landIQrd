module WorkOrders
  # Creates a work order and accepts the contractor on it, skipping proposals.
  class QuickAssign
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(landlord:, quick_job:)
      @landlord = landlord
      @quick_job = quick_job
    end

    def call
      relationship = relationship_for(contractor)
      unit = unit_for_landlord

      work_order = nil
      WorkOrder.transaction do
        work_order = WorkOrder.create!(
          unit: unit,
          created_by: @landlord,
          title: @quick_job.title,
          description: @quick_job.description,
          category: @quick_job.category,
          priority: @quick_job.priority,
          price_cents: @quick_job.price_cents,
          status: :open
        )
        work_order.photos.attach(@quick_job.attached_photos) if @quick_job.attached_photos.any?
        work_order.work_order_assignments.create!(
          contractor: contractor,
          status: :pending,
          scheduled_at: scheduled_at
        )
        RecordEvent.call(
          work_order: work_order,
          user: @landlord,
          action: "assigned",
          metadata: {
            "contractor_name" => contractor.display_name,
            "relationship" => relationship.kind
          }
        )
      end

      work_order
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence
    end

    private

    def contractor
      @contractor ||= User.contractor.find_by(id: @quick_job.contractor_id)
    end

    def relationship_for(contractor)
      raise Error, "Choose a contractor you already work with." if contractor.nil?

      relationship = @landlord.contractor_relationships.find_by(contractor_id: contractor.id)
      raise Error, "Save this contractor as a personal or business contact before assigning a job directly." if relationship.nil?
      raise Error, "This contractor has not accepted the contact yet." unless relationship.status_accepted?

      relationship
    end

    def unit_for_landlord
      unit = Unit.joins(:property).find_by(id: @quick_job.unit_id, properties: { landlord_id: @landlord.id })
      raise Error, "Choose one of your units." if unit.nil?

      unit
    end

    def scheduled_at
      value = @quick_job.scheduled_at
      return if value.blank?

      value.is_a?(Time) || value.is_a?(DateTime) || value.is_a?(ActiveSupport::TimeWithZone) ? value : Time.zone.parse(value.to_s)
    end
  end
end
