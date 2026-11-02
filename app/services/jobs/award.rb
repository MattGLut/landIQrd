module Jobs
  # Awards a proposal: creates the WorkOrder and assignment, marks the winning
  # proposal awarded, declines the rest, and closes the job.
  class Award
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(job:, proposal:, awarded_by:)
      @job = job
      @proposal = proposal
      @awarded_by = awarded_by
    end

    def call
      work_order = nil

      Job.transaction do
        @job.lock!
        validate!

        work_order = create_work_order!
        copy_photos(work_order)
        work_order.work_order_assignments.create!(contractor: @proposal.contractor, status: :accepted)

        @proposal.update!(status: :awarded)
        @job.proposals.submitted.where.not(id: @proposal.id).update_all(status: Proposal.statuses[:declined], updated_at: Time.current)
        @job.update!(status: :awarded, work_order: work_order)
      end

      Notifications::Deliver.proposal_awarded(@proposal, actor: @awarded_by)
      work_order
    end

    private

    def validate!
      raise Error, "This job is no longer open" unless @job.status_open?
      raise Error, "Proposal does not belong to this job" unless @proposal.job_id == @job.id
      raise Error, "Only submitted proposals can be awarded" unless @proposal.submitted?
      raise Error, "Add a unit to #{@job.property.name} before awarding work" if target_unit.nil?
    end

    def target_unit
      @target_unit ||= @job.unit || @job.property.units.order(:id).first
    end

    def create_work_order!
      WorkOrder.create!(
        unit: target_unit,
        created_by: @awarded_by,
        title: @job.title,
        description: work_order_description,
        category: @job.work_order_category,
        priority: :medium,
        price_cents: @proposal.amount_cents,
        proposal: @proposal
      )
    end

    def work_order_description
      parts = [ @job.description.presence ]
      parts << "Awarded scope: #{@proposal.scope}"
      parts << "Exclusions: #{@proposal.exclusions}" if @proposal.exclusions.present?
      parts << "Earliest start: #{@proposal.earliest_start.to_fs(:long)}" if @proposal.earliest_start
      parts << "Estimated duration: #{@proposal.duration_label}"
      parts.compact.join("\n\n")
    end

    def copy_photos(work_order)
      images = @job.attachments.select(&:image?)
      work_order.photos.attach(images.map(&:blob)) if images.any?
    end
  end
end
