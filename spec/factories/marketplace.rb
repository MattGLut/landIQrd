FactoryBot.define do
  factory :job do
    association :property
    created_by { property.landlord }
    title { "Roof repair" }
    description { "Shingles lifted on the north slope." }
    trades { %w[roofing] }
    proposal_deadline { Date.current + 14 }
    status { :draft }

    trait :open do
      status { :open }
      published_at { Time.current }
    end

    trait :with_unit do
      unit { association :unit, property: property }
    end

    trait :walkthrough_required do
      walkthrough_required { true }
    end
  end

  factory :walkthrough_slot do
    association :job, factory: %i[job open]
    starts_at { 3.days.from_now.change(min: 0) }
    ends_at { starts_at + 1.hour }
    capacity { 1 }
  end

  factory :walkthrough_booking do
    association :walkthrough_slot
    association :contractor, factory: :contractor
    status { :confirmed }
  end

  factory :proposal do
    association :job, factory: %i[job open]
    association :contractor, factory: :contractor, trades: %w[roofing]
    amount_cents { 245_000 }
    scope { "Replace damaged shingles and flashing." }
    earliest_start { Date.current + 5 }
    estimated_duration_days { 3 }
    status { :submitted }
  end
end
