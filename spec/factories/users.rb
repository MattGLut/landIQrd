FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { Faker::PhoneNumber.cell_phone }
    role { :tenant }

    trait :tenant do
      role { :tenant }
    end

    trait :landlord do
      role { :landlord }
      company_name { Faker::Company.name }
    end

    trait :contractor do
      role { :contractor }
      company_name { Faker::Company.name }
    end

    trait :admin do
      role { :admin }
    end

    factory :tenant, traits: [ :tenant ]
    factory :landlord, traits: [ :landlord ]
    factory :contractor, traits: [ :contractor ]
    factory :admin, traits: [ :admin ]
  end
end
