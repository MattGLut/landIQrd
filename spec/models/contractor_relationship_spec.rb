require "rails_helper"

RSpec.describe ContractorRelationship, type: :model do
  let(:landlord) { create(:landlord) }
  let(:contractor) { create(:contractor) }

  it "saves a personal or business contact once per landlord" do
    relationship = described_class.create!(landlord: landlord, contractor: contractor, kind: :business)

    expect(relationship).to be_kind_business
    expect(relationship.label).to eq("Business contact")

    duplicate = described_class.new(landlord: landlord, contractor: contractor, kind: :personal)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:contractor_id]).to include("is already saved as a contact")
  end

  it "rejects a landlord who is not a landlord and a contact who is not a contractor" do
    tenant = create(:tenant)
    relationship = described_class.new(landlord: tenant, contractor: landlord)

    expect(relationship).not_to be_valid
    expect(relationship.errors[:landlord]).to include("must be a landlord")
    expect(relationship.errors[:contractor]).to include("must be a contractor")
  end
end
