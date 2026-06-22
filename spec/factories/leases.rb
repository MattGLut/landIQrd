FactoryBot.define do
  factory :lease do
    association :unit
    association :tenant, factory: :tenant
    start_date { Date.current }
    end_date { 1.year.from_now.to_date }
    rent_amount { 1500 }
    deposit_amount { 1500 }
    status { :active }
  end
end
