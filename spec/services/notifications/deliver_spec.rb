require "rails_helper"

RSpec.describe Notifications::Deliver do
  include ActiveJob::TestHelper

  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }

  after { clear_enqueued_jobs }

  describe ".work_order_created" do
    it "emails the landlord but not the creating tenant" do
      expect {
        described_class.work_order_created(work_order, actor: tenant)
      }.to have_enqueued_mail(NotificationMailer, :work_order_created).with(work_order, landlord)
    end
  end

  describe ".work_order_status_changed" do
    it "emails stakeholders except the actor" do
      create(:work_order_assignment, work_order: work_order, contractor: contractor)
      work_order.reload

      expect {
        described_class.work_order_status_changed(work_order, actor: landlord)
      }.to have_enqueued_mail(NotificationMailer, :work_order_status_changed).exactly(2).times
    end
  end

  describe ".contractor_assigned" do
    it "emails the contractor" do
      assignment = create(:work_order_assignment, work_order: work_order, contractor: contractor)

      expect {
        described_class.contractor_assigned(assignment, actor: landlord)
      }.to have_enqueued_mail(NotificationMailer, :contractor_assigned).with(assignment)
    end
  end

  describe ".new_message" do
    it "emails other participants" do
      conversation = Conversation.direct_between!(tenant, landlord)
      message = conversation.messages.create!(author: tenant, body: "Ping")

      expect {
        described_class.new_message(message, actor: tenant)
      }.to have_enqueued_mail(NotificationMailer, :new_message).with(message, landlord)
    end
  end

  describe ".lease_invitation" do
    it "emails the invitee" do
      invitation = create(:lease_invitation, unit: unit, invited_by: landlord)

      expect {
        described_class.lease_invitation(invitation)
      }.to have_enqueued_mail(NotificationMailer, :lease_invitation).with(invitation)
    end
  end

  describe ".lease_invitation_accepted" do
    it "emails the inviting landlord" do
      invitation = create(:lease_invitation, unit: unit, invited_by: landlord)
      tenant = create(:tenant)

      expect {
        described_class.lease_invitation_accepted(invitation, actor: tenant)
      }.to have_enqueued_mail(NotificationMailer, :lease_invitation_accepted).with(invitation)
    end
  end

  describe ".lease_expiring" do
    it "emails tenant and landlord" do
      lease = create(:lease, unit: unit, tenant: tenant, status: :active)

      expect {
        described_class.lease_expiring(lease)
      }.to have_enqueued_mail(NotificationMailer, :lease_expiring).exactly(2).times
    end
  end
end
