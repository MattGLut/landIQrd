FactoryBot.define do
  factory :conversation do
    subject { "Direct message" }

    trait :for_work_order do
      association :work_order
    end
  end

  factory :message do
    association :conversation
    association :author, factory: :tenant
    body { "Hello there" }
  end
end
