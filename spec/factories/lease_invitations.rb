FactoryBot.define do
  factory :lease_invitation do
    association :unit
    invited_by { unit.property.landlord }
    sequence(:email) { |n| "invite#{n}@example.com" }
    start_date { Date.current }
    end_date { 1.year.from_now.to_date }
    rent_amount { 1500 }
    deposit_amount { 1500 }
    status { :pending }
    expires_at { 14.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
      status { :expired }
    end

    trait :accepted do
      status { :accepted }
      accepted_at { Time.current }
      association :lease
    end
  end
end
