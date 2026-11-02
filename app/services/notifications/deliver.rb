module Notifications
  class Deliver
    def self.work_order_created(work_order, actor:)
      landlord = work_order.unit.property.landlord
      deliver_to(landlord, actor, type: :work_order_created, sms: SmsMessages.work_order_created(work_order)) do
        NotificationMailer.work_order_created(work_order, landlord).deliver_later
      end
    end

    def self.work_order_status_changed(work_order, actor:)
      recipients = [
        work_order.created_by,
        work_order.unit.property.landlord,
        *work_order.contractors
      ].uniq

      recipients.each do |recipient|
        deliver_to(recipient, actor, type: :work_order_status_changed, sms: SmsMessages.work_order_status_changed(work_order)) do
          NotificationMailer.work_order_status_changed(work_order, recipient).deliver_later
        end
      end
    end

    def self.contractor_assigned(assignment, actor:)
      deliver_to(assignment.contractor, actor, type: :contractor_assigned, sms: SmsMessages.contractor_assigned(assignment)) do
        NotificationMailer.contractor_assigned(assignment).deliver_later
      end
    end

<<<<<<< Updated upstream
=======
    def self.assignment_responded(assignment, actor:)
      landlord = assignment.work_order.unit.property.landlord
      deliver_to(landlord, actor, type: :assignment_responded, sms: SmsMessages.assignment_responded(assignment)) do
        NotificationMailer.assignment_responded(assignment).deliver_later
      end
    end

    def self.relationship_requested(relationship, actor:)
      deliver_to(relationship.contractor, actor, type: :relationship_requested, sms: SmsMessages.relationship_requested(relationship)) do
        NotificationMailer.relationship_requested(relationship).deliver_later
      end
    end

    def self.relationship_responded(relationship, actor:)
      deliver_to(relationship.landlord, actor, type: :relationship_responded, sms: SmsMessages.relationship_responded(relationship)) do
        NotificationMailer.relationship_responded(relationship).deliver_later
      end
    end

>>>>>>> Stashed changes
    def self.new_message(message, actor:)
      message.conversation.participants.where.not(id: actor.id).find_each do |recipient|
        deliver_to(recipient, actor, type: :new_message, sms: SmsMessages.new_message(message)) do
          NotificationMailer.new_message(message, recipient).deliver_later
        end
      end
    end

    def self.lease_invitation(invitation)
      NotificationMailer.lease_invitation(invitation).deliver_later
    end

    def self.lease_expiring(lease)
      [ lease.tenant, lease.landlord ].uniq.each do |recipient|
        deliver_to(recipient, nil, type: :lease_expiring, sms: SmsMessages.lease_expiring(lease)) do
          NotificationMailer.lease_expiring(lease, recipient).deliver_later
        end
      end
    end

    def self.lease_invitation_accepted(invitation, actor:)
      deliver_to(invitation.invited_by, actor, type: :lease_invitation_accepted, sms: SmsMessages.lease_invitation_accepted(invitation)) do
        NotificationMailer.lease_invitation_accepted(invitation).deliver_later
      end
    end

    # Emails every in-area contractor whose trades overlap the job and who opted in.
    def self.matching_job_posted(job, actor: nil)
      matches = Jobs::MatchContractors.call(
        trades: job.trades,
        city: job.property.city,
        state: job.property.state
      )

      matches.each do |match|
        contractor = match.contractor
        next unless match.in_area? && contractor.notify_matching_jobs?

        deliver_to(contractor, actor, type: :matching_job_posted, sms: SmsMessages.matching_job_posted(job)) do
          NotificationMailer.matching_job_posted(job, contractor).deliver_later
        end
      end
    end

    def self.proposal_received(proposal, actor:)
      landlord = proposal.job.property.landlord
      deliver_to(landlord, actor, type: :proposal_received, sms: SmsMessages.proposal_received(proposal)) do
        NotificationMailer.proposal_received(proposal, landlord).deliver_later
      end
    end

    def self.proposal_awarded(proposal, actor:)
      deliver_to(proposal.contractor, actor, type: :proposal_awarded, sms: SmsMessages.proposal_awarded(proposal)) do
        NotificationMailer.proposal_awarded(proposal).deliver_later
      end
    end

    def self.deliver_to(recipient, actor, type:, sms: nil)
      return if recipient.nil? || recipient.id == actor&.id

      yield if recipient.email_notification_enabled?(type)

      if sms.present? && recipient.sms_notification_enabled?(type)
        SendSmsJob.perform_later(recipient.id, sms)
      end
    end
    private_class_method :deliver_to
  end
end
