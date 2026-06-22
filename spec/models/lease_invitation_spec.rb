require "rails_helper"

RSpec.describe LeaseInvitation, type: :model do
  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:invited_by).class_name("User") }
  it { is_expected.to belong_to(:lease).optional }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:start_date) }

  it "generates a token and expiration on create" do
    invitation = create(:lease_invitation)
    expect(invitation.token).to be_present
    expect(invitation.expires_at).to be_future
  end

  it "is invalid when end_date precedes start_date" do
    invitation = build(:lease_invitation, start_date: Date.current, end_date: 1.day.ago.to_date)
    expect(invitation).not_to be_valid
    expect(invitation.errors[:end_date]).to be_present
  end

  describe "#usable?" do
    it "is true for pending invitations that have not expired" do
      expect(build(:lease_invitation)).to be_usable
    end

    it "is false for expired invitations" do
      expect(build(:lease_invitation, :expired)).not_to be_usable
    end
  end

  describe "#accept!" do
    let(:tenant) { create(:tenant, email: "newtenant@example.com") }
    let(:invitation) { create(:lease_invitation, email: tenant.email) }

    it "creates a draft lease and marks the invitation accepted" do
      lease = invitation.accept!(tenant)

      expect(lease).to be_persisted
      expect(lease).to be_draft
      expect(lease.tenant).to eq(tenant)
      expect(invitation.reload).to be_status_accepted
      expect(invitation.lease).to eq(lease)
    end

    it "raises when the invitation is no longer valid" do
      invitation.update!(expires_at: 1.day.ago)
      expect { invitation.accept!(tenant) }.to raise_error("Invitation is no longer valid")
    end
  end
end
