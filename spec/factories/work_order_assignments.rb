FactoryBot.define do
  factory :work_order_assignment do
    association :work_order
    association :contractor, factory: :contractor
    status { :pending }
  end
end
