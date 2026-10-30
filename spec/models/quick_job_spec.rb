require "rails_helper"

RSpec.describe QuickJob do
  it "turns a dollar amount into cents" do
    job = described_class.new(price: "$1,250.50")

    expect(job.price_cents).to eq(125_050)
  end

  it "rejects a blank title and a price that is not positive" do
    job = described_class.new(price: "0")

    expect(job).not_to be_valid
    expect(job.errors[:title]).to include("can't be blank")
    expect(job.errors[:contractor_id]).to include("can't be blank")
    expect(job.errors[:unit_id]).to include("can't be blank")
    expect(job.errors[:price]).to include("must be a positive amount")
  end
end
