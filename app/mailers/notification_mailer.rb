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
    mail(to: assignment.contractor.email, subject: "You've been assigned: #{@work_order.title}")
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

  def lease_expiring(lease, recipient)
    @lease = lease
    @recipient = recipient
    mail(to: recipient.email, subject: "Lease expiring soon: #{lease.unit.full_label}")
  end
end
