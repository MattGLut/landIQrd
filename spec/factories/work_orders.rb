FactoryBot.define do
  factory :work_order do
    association :unit
    association :created_by, factory: :tenant
    title { "Leaky kitchen faucet" }
    description { "Water keeps dripping under the sink." }
    priority { :medium }
    status { :open }
  end
end
