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

  describe "#email_notification_enabled?" do
    it "defaults to enabled when preference is unset" do
      user = build(:tenant, email_notification_preferences: {})
      expect(user.email_notification_enabled?(:new_message)).to be(true)
    end

    it "returns false when preference is disabled" do
      user = build(:tenant, email_notification_preferences: { "new_message" => false })
      expect(user.email_notification_enabled?(:new_message)).to be(false)
    end
  end

  describe "#applicable_email_notification_types" do
    it "returns tenant notification types for tenants" do
      user = build(:tenant)
      keys = user.applicable_email_notification_types.keys

      expect(keys).to contain_exactly(:work_order_status_changed, :new_message, :lease_expiring)
    end

    it "returns landlord notification types for landlords" do
      user = build(:landlord)
      keys = user.applicable_email_notification_types.keys

      expect(keys).to contain_exactly(
        :work_order_created,
        :work_order_status_changed,
        :new_message,
        :lease_invitation_accepted,
        :lease_expiring
      )
    end

    it "returns contractor notification types for contractors" do
      user = build(:contractor)
      keys = user.applicable_email_notification_types.keys

      expect(keys).to contain_exactly(:work_order_status_changed, :contractor_assigned, :new_message)
    end
  end

  describe "website_url validation" do
    it "allows blank or valid http(s) urls" do
      user = build(:contractor, website_url: "https://example.com")
      expect(user).to be_valid

      user.website_url = ""
      expect(user).to be_valid
    end

    it "rejects invalid urls" do
      user = build(:contractor, website_url: "not-a-url")
      expect(user).not_to be_valid
      expect(user.errors[:website_url]).to be_present
    end
  end

  describe "portfolio helpers" do
    let(:contractor) { create(:contractor) }

    it "#matches_category? reflects portfolio items" do
      create(:contractor_portfolio_item, contractor: contractor, category: "plumbing")

      expect(contractor.matches_category?("plumbing")).to be(true)
      expect(contractor.matches_category?("hvac")).to be(false)
    end

    it "#portfolio_categories returns distinct categories" do
      create(:contractor_portfolio_item, contractor: contractor, category: "plumbing", title: "Job A")
      create(:contractor_portfolio_item, contractor: contractor, category: "plumbing", title: "Job B")
      create(:contractor_portfolio_item, contractor: contractor, category: "hvac", title: "Job C")

      expect(contractor.portfolio_categories).to contain_exactly("plumbing", "hvac")
    end
  end
end
