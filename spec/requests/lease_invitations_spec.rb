require "rails_helper"

RSpec.describe "LeaseInvitations", type: :request do
  include ActiveJob::TestHelper

  let(:landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }

  after { clear_enqueued_jobs }

  describe "POST /units/:unit_id/lease_invitations" do
    it "creates an invitation and enqueues email" do
      sign_in landlord
      expect {
        post unit_lease_invitations_path(unit), params: {
          lease_invitation: {
            email: "newtenant@example.com",
            start_date: Date.current,
            end_date: 1.year.from_now.to_date,
            rent_amount: 1500,
            deposit_amount: 1500
          }
        }
      }.to change(LeaseInvitation, :count).by(1)
        .and have_enqueued_mail(NotificationMailer, :lease_invitation)

      expect(response).to redirect_to(unit_path(unit))
    end

    it "forbids a tenant from inviting" do
      sign_in create(:tenant)
      post unit_lease_invitations_path(unit), params: {
        lease_invitation: { email: "x@example.com", start_date: Date.current }
      }
      expect(LeaseInvitation.count).to eq(0)
    end
  end

  describe "GET /invites/:token" do
    it "redirects guests to signup with the invite token" do
      invitation = create(:lease_invitation, unit: unit, invited_by: landlord, email: "guest@example.com")

      get invite_path(invitation.token)
      expect(response).to redirect_to(new_user_registration_path(invite_token: invitation.token, email: invitation.email))
    end

    it "rejects expired invitations" do
      invitation = create(:lease_invitation, :expired, unit: unit, invited_by: landlord)

      get invite_path(invitation.token)
      expect(response).to redirect_to(new_user_registration_path)
      expect(flash[:alert]).to include("no longer valid")
    end
  end
end
