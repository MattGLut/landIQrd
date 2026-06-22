FactoryBot.define do
  factory :unit do
    association :property
    sequence(:label) { |n| "Unit #{n}" }
    bedrooms { 2 }
    bathrooms { 1.5 }
    square_feet { 900 }
  end
end
