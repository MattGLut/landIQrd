module Notifications
  class Deliver
    def self.work_order_created(work_order, actor:)
      landlord = work_order.unit.property.landlord
      deliver_to(landlord, actor, type: :work_order_created) do
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
        deliver_to(recipient, actor, type: :work_order_status_changed) do
          NotificationMailer.work_order_status_changed(work_order, recipient).deliver_later
        end
      end
    end

    def self.contractor_assigned(assignment, actor:)
      deliver_to(assignment.contractor, actor, type: :contractor_assigned) do
        NotificationMailer.contractor_assigned(assignment).deliver_later
      end
    end

    def self.new_message(message, actor:)
      message.conversation.participants.where.not(id: actor.id).find_each do |recipient|
        deliver_to(recipient, actor, type: :new_message) do
          NotificationMailer.new_message(message, recipient).deliver_later
        end
      end
    end

    def self.lease_invitation(invitation)
      NotificationMailer.lease_invitation(invitation).deliver_later
    end

    def self.lease_expiring(lease)
      [ lease.tenant, lease.landlord ].uniq.each do |recipient|
        deliver_to(recipient, nil, type: :lease_expiring) do
          NotificationMailer.lease_expiring(lease, recipient).deliver_later
        end
      end
    end

    def self.lease_invitation_accepted(invitation, actor:)
      deliver_to(invitation.invited_by, actor, type: :lease_invitation_accepted) do
        NotificationMailer.lease_invitation_accepted(invitation).deliver_later
      end
    end

    def self.deliver_to(recipient, actor, type:)
      return if recipient.nil? || recipient.id == actor&.id
      return unless recipient.email_notification_enabled?(type)

      yield
    end
    private_class_method :deliver_to
  end
end
