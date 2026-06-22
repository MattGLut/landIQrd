require "rails_helper"

RSpec.describe User, type: :model do
  describe "#display_name" do
    it "prefers preferred name, then company, then full name" do
      user = build(:tenant, first_name: "Toni", last_name: "Tenant", preferred_name: "T", company_name: "Co")
      expect(user.display_name).to eq("T")

      user.preferred_name = nil
      expect(user.display_name).to eq("Co")

      user.company_name = nil
      expect(user.display_name).to eq("Toni Tenant")
    end
  end

  describe "#greeting_name" do
    it "prefers preferred name over first name" do
      user = build(:tenant, first_name: "Toni", preferred_name: "T")
      expect(user.greeting_name).to eq("T")
    end
  end

  describe "avatar validations" do
    it "rejects unsupported content types" do
      user = create(:tenant)
      user.avatar.attach(io: StringIO.new("not-an-image"), filename: "bad.txt", content_type: "text/plain")
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to be_present
    end
  end
end
