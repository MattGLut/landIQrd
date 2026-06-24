FactoryBot.define do
  factory :unit do
    association :property
    sequence(:label) { |n| "Unit #{n}" }
    bedrooms { 2 }
    bathrooms { 1.5 }
    square_feet { 900 }
    features { {} }

    trait :commercial do
      association :property, factory: [ :property, :commercial ]
      bedrooms { nil }
      bathrooms { nil }
      square_feet { 1500 }
      features { { "use_class" => "retail", "parking_spaces" => 2 } }
    end

    trait :undeveloped do
      association :property, factory: [ :property, :undeveloped ]
      bedrooms { nil }
      bathrooms { nil }
      square_feet { nil }
      acreage { 2.5 }
      features { { "zoning" => "R-1", "water_hookup" => true, "electric_hookup" => true } }
    end
  end
end
