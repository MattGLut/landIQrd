module Notifications
  class SmsMessages
    class << self
      include Rails.application.routes.url_helpers

      def work_order_created(work_order)
        %(New work request: "#{clip(work_order.title)}". #{work_order_url(work_order)})
      end

      def work_order_status_changed(work_order)
        %(Work order updated: "#{clip(work_order.title)}". #{work_order_url(work_order)})
      end

      def contractor_assigned(assignment)
        work_order = assignment.work_order
        %(Job waiting for you: "#{clip(work_order.title)}". #{work_order_url(work_order)})
      end

      def assignment_responded(assignment)
        work_order = assignment.work_order
        verb = assignment.status_accepted? ? "accepted" : "declined"
        %(#{assignment.contractor.display_name} #{verb} "#{clip(work_order.title)}". #{work_order_url(work_order)})
      end

      def relationship_requested(relationship)
        %(#{relationship.landlord.display_name} wants to assign you jobs directly. #{contractor_relationships_url})
      end

      def relationship_responded(relationship)
        verb = relationship.status_accepted? ? "accepted" : "declined"
        %(#{relationship.contractor.display_name} #{verb} your contact request. #{contractor_url(relationship.contractor)})
      end

      def new_message(message)
        %(New message in #{clip(message.conversation.title)}. #{conversation_url(message.conversation)})
      end

      def lease_invitation_accepted(invitation)
        %(#{invitation.email} accepted your lease invitation. #{unit_url(invitation.unit)})
      end

      def lease_expiring(lease)
        %(Lease ended: #{clip(lease.unit.full_label)}. #{lease_url(lease)})
      end

      def matching_job_posted(job)
        %(New #{job.trade_labels.to_sentence} job: "#{clip(job.title)}". #{contractor_available_job_url(job)})
      end

      def proposal_received(proposal)
        %(New proposal on "#{clip(proposal.job.title)}". #{job_proposals_url(proposal.job)})
      end

      def proposal_awarded(proposal)
        work_order = proposal.job.work_order
        link = work_order ? work_order_url(work_order) : contractor_available_job_url(proposal.job)
        %(Your proposal was awarded: "#{clip(proposal.job.title)}". #{link})
      end

      def default_url_options
        Rails.application.config.action_mailer.default_url_options || {}
      end

      private

      def clip(text)
        text.to_s.squish.truncate(60)
      end
    end
  end
end
