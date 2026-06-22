require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "roles" do
    it do
      is_expected.to define_enum_for(:role)
        .with_values(tenant: 0, landlord: 1, contractor: 2, admin: 3)
    end

    it "defaults to tenant" do
      expect(User.new.role).to eq("tenant")
    end
  end

  describe "#full_name" do
    it "joins first and last name" do
      user = build(:user, first_name: "Ada", last_name: "Lovelace")
      expect(user.full_name).to eq("Ada Lovelace")
    end
  end

  describe "#display_name" do
    it "prefers company name when present" do
      user = build(:landlord, company_name: "Acme Realty", first_name: "Ada", last_name: "Lovelace")
      expect(user.display_name).to eq("Acme Realty")
    end

    it "falls back to full name without a company" do
      user = build(:tenant, first_name: "Ada", last_name: "Lovelace", company_name: nil)
      expect(user.display_name).to eq("Ada Lovelace")
    end
  end
end
