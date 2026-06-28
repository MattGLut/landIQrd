require "rails_helper"

RSpec.describe ContractorPortfolioItem, type: :model do
  it { is_expected.to belong_to(:contractor).class_name("User") }

  it "requires a title and valid category" do
    item = build(:contractor_portfolio_item, title: nil, category: "invalid")
    expect(item).not_to be_valid
    expect(item.errors[:title]).to be_present
    expect(item.errors[:category]).to be_present
  end

  it "requires at least one photo on create" do
    item = build(:contractor_portfolio_item)
    item.photos.purge
    expect(item).not_to be_valid
    expect(item.errors[:photos]).to be_present
  end

  it "requires the owner to be a contractor" do
    item = build(:contractor_portfolio_item, contractor: create(:tenant))
    expect(item).not_to be_valid
    expect(item.errors[:contractor]).to include("must be a contractor")
  end
end
