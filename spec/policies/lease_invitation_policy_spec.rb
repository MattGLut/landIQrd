require "rails_helper"

RSpec.describe LeaseInvitationPolicy do
  let(:landlord) { create(:landlord) }
  let(:other_landlord) { create(:landlord) }
  let(:property) { create(:property, landlord: landlord) }
  let(:unit) { create(:unit, property: property) }
  let(:invitation) { build(:lease_invitation, unit: unit, invited_by: landlord) }

  def policy_for(user)
    described_class.new(user, invitation)
  end

  it "lets the owning landlord create invitations" do
    expect(policy_for(landlord).create?).to be(true)
    expect(policy_for(landlord).new?).to be(true)
  end

  it "forbids other landlords" do
    expect(policy_for(other_landlord).create?).to be(false)
  end

  it "forbids tenants" do
    expect(policy_for(create(:tenant)).create?).to be(false)
  end
end
