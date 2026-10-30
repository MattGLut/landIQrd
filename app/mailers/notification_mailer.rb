class NotificationMailer < ApplicationMailer
  def work_order_created(work_order, recipient)
    @work_order = work_order
    @recipient = recipient
    mail(to: recipient.email, subject: "New work request: #{work_order.title}")
  end

  def work_order_status_changed(work_order, recipient)
    @work_order = work_order
    @recipient = recipient
    mail(to: recipient.email, subject: "Work order updated: #{work_order.title}")
  end

  def contractor_assigned(assignment)
    @assignment = assignment
    @work_order = assignment.work_order
    mail(to: assignment.contractor.email, subject: "Job waiting for you: #{@work_order.title}")
  end

  def assignment_responded(assignment)
    @assignment = assignment
    @work_order = assignment.work_order
    landlord = @work_order.unit.property.landlord
    verb = assignment.status_accepted? ? "accepted" : "declined"
    mail(to: landlord.email, subject: "#{assignment.contractor.display_name} #{verb}: #{@work_order.title}")
  end

  def relationship_requested(relationship)
    @relationship = relationship
    mail(
      to: relationship.contractor.email,
      subject: "#{relationship.landlord.display_name} wants to assign you jobs directly"
    )
  end

  def relationship_responded(relationship)
    @relationship = relationship
    verb = relationship.status_accepted? ? "accepted" : "declined"
    mail(
      to: relationship.landlord.email,
      subject: "#{relationship.contractor.display_name} #{verb} your contact request"
    )
  end

  def new_message(message, recipient)
    @message = message
    @conversation = message.conversation
    @recipient = recipient
    mail(to: recipient.email, subject: "New message in #{@conversation.title}")
  end

  def lease_invitation(invitation)
    @invitation = invitation
    mail(to: invitation.email, subject: "You're invited to join #{invitation.unit.property.name}")
  end

  def lease_invitation_accepted(invitation)
    @invitation = invitation
    mail(to: invitation.invited_by.email, subject: "#{invitation.email} accepted your lease invitation")
  end

  def matching_job_posted(job, recipient)
    @job = job
    @recipient = recipient
    mail(to: recipient.email, subject: "New #{job.trade_labels.to_sentence} job: #{job.title}")
  end

  def proposal_received(proposal, recipient)
    @proposal = proposal
    @job = proposal.job
    @recipient = recipient
    mail(to: recipient.email, subject: "New proposal on #{@job.title}")
  end

  def proposal_awarded(proposal)
    @proposal = proposal
    @job = proposal.job
    @work_order = @job.work_order
    mail(to: proposal.contractor.email, subject: "Your proposal was awarded: #{@job.title}")
  end

  def lease_expiring(lease, recipient)
    @lease = lease
    @recipient = recipient
    mail(to: recipient.email, subject: "Lease ended: #{lease.unit.full_label}")
  end
end
