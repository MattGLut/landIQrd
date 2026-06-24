FactoryBot.define do
  factory :property do
    association :landlord, factory: :landlord
    name { Faker::Address.community }
    address_line1 { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    postal_code { Faker::Address.zip_code }
    property_type { :residential }
    features { {} }

    trait :commercial do
      property_type { :commercial }
      features { { "ada_accessible" => true } }
    end

    trait :undeveloped do
      property_type { :undeveloped }
      features { { "fenced" => true } }
    end
  end
end
