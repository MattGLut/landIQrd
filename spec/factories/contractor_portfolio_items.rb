FactoryBot.define do
  factory :contractor_portfolio_item do
    association :contractor, factory: :contractor
    sequence(:title) { |n| "Portfolio project #{n}" }
    description { "Completed work for a satisfied client." }
    category { "plumbing" }
    position { 0 }

    after(:build) do |item|
      next if item.photos.attached?

      item.photos.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end
  end
end
