require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  let(:landlord) { create(:landlord) }
  let(:tenant) { create(:tenant) }
  let(:contractor) { create(:contractor) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:work_order) { create(:work_order, unit: unit, created_by: tenant) }

  it "sends work order created mail" do
    mail = described_class.work_order_created(work_order, landlord)
    expect(mail.to).to eq([ landlord.email ])
    expect(mail.subject).to include(work_order.title)
  end

  it "sends work order status changed mail" do
    mail = described_class.work_order_status_changed(work_order, tenant)
    expect(mail.to).to eq([ tenant.email ])
    expect(mail.body.encoded).to include("In progress").or include("Open")
  end

  it "sends contractor assigned mail" do
    assignment = create(:work_order_assignment, work_order: work_order, contractor: contractor)
    mail = described_class.contractor_assigned(assignment)
    expect(mail.to).to eq([ contractor.email ])
    expect(mail.subject).to include(work_order.title)
  end

  it "sends new message mail" do
    conversation = Conversation.direct_between!(tenant, landlord)
    message = conversation.messages.create!(author: tenant, body: "Need an update")
    mail = described_class.new_message(message, landlord)
    expect(mail.to).to eq([ landlord.email ])
    expect(mail.body.encoded).to include("Need an update")
  end

  it "sends lease invitation mail" do
    invitation = create(:lease_invitation, unit: unit, invited_by: landlord)
    mail = described_class.lease_invitation(invitation)
    expect(mail.to).to eq([ invitation.email ])
    expect(mail.body.encoded).to include(invitation.token)
  end

  it "sends lease invitation accepted mail" do
    invitation = create(:lease_invitation, unit: unit, invited_by: landlord)
    mail = described_class.lease_invitation_accepted(invitation)
    expect(mail.to).to eq([ landlord.email ])
  end

  it "sends lease ended mail" do
    lease = create(:lease, unit: unit, tenant: tenant, end_date: 2.weeks.from_now.to_date)
    mail = described_class.lease_expiring(lease, tenant)
    expect(mail.to).to eq([ tenant.email ])
    expect(mail.subject).to include("Lease ended")
    expect(mail.body.encoded).to include("ended on")
    expect(mail.body.encoded).to include(lease.end_date.to_fs(:long))
  end
end
