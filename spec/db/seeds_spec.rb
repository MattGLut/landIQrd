require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "does not create users in production" do
    allow(Rails.env).to receive(:production?).and_return(true)

    expect { load Rails.root.join("db/seeds.rb") }.not_to change(User, :count)
  end
end
