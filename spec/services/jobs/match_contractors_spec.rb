require "rails_helper"

RSpec.describe Jobs::MatchContractors do
  def contractor_with(trades:, city: nil, state: nil, company: "Co")
    create(:contractor, trades: trades, service_city: city, service_state: state, company_name: company)
  end

  it "returns nothing without trades" do
    contractor_with(trades: %w[roofing])
    expect(described_class.call(trades: [])).to eq([])
  end

  it "only returns contractors sharing a trade" do
    roofer = contractor_with(trades: %w[roofing])
    contractor_with(trades: %w[plumbing])

    matches = described_class.call(trades: %w[roofing], city: "Austin", state: "TX")
    expect(matches.map(&:contractor)).to eq([ roofer ])
  end

  it "scores trade overlap plus location and sorts best first" do
    local = contractor_with(trades: %w[roofing painting], city: "Austin", state: "TX", company: "Local")
    statewide = contractor_with(trades: %w[roofing painting], city: "Dallas", state: "TX", company: "Statewide")
    half = contractor_with(trades: %w[roofing], city: "Austin", state: "TX", company: "Half")

    matches = described_class.call(trades: %w[roofing painting], city: "austin", state: "tx")

    expect(matches.map(&:contractor)).to eq([ local, statewide, half ])
    expect(matches.map(&:score)).to eq([ 100, 85, 65 ])
    expect(matches.first.shared_trades).to match_array(%w[roofing painting])
  end

  it "marks out-of-state contractors as out of area but keeps blank service areas in area" do
    far = contractor_with(trades: %w[roofing], city: "Miami", state: "FL")
    anywhere = contractor_with(trades: %w[roofing])

    matches = described_class.call(trades: %w[roofing], city: "Austin", state: "TX").index_by(&:contractor)
    expect(matches[far]).not_to be_in_area
    expect(matches[anywhere]).to be_in_area
  end

  it "respects the limit" do
    3.times { contractor_with(trades: %w[roofing]) }
    expect(described_class.call(trades: %w[roofing], limit: 2).size).to eq(2)
  end
end
