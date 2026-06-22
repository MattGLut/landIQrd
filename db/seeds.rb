# Idempotent demo/dev seed data. Safe to run repeatedly.
# Default password for every seeded account is "password123".

if Rails.env.production?
  puts "Skipping seeds in production."
  return
end

# Never seed the test database; specs rely on a clean slate (db:prepare would
# otherwise seed a freshly created CI database).
if Rails.env.test?
  puts "Skipping seeds in the test environment."
  return
end

def upsert_user(email, role:, **attrs)
  User.find_or_create_by!(email: email) do |user|
    user.role = role
    user.password = "password123"
    user.password_confirmation = "password123"
    user.assign_attributes(attrs)
  end
end

admin = upsert_user("admin@propman.test", role: :admin, first_name: "Avery", last_name: "Admin")
landlord = upsert_user("landlord@propman.test", role: :landlord, first_name: "Lana", last_name: "Lord", company_name: "Lord Property Group")
tenant = upsert_user("tenant@propman.test", role: :tenant, first_name: "Toni", last_name: "Tenant")
contractor = upsert_user("contractor@propman.test", role: :contractor, first_name: "Casey", last_name: "Contractor", company_name: "FixIt Co")

property = Property.find_or_create_by!(landlord: landlord, name: "Maple Court") do |p|
  p.address_line1 = "123 Maple St"
  p.city = "Austin"
  p.state = "TX"
  p.postal_code = "78701"
end

unit = Unit.find_or_create_by!(property: property, label: "Apt 1A") do |u|
  u.bedrooms = 2
  u.bathrooms = 1.0
  u.square_feet = 850
end

lease = Lease.find_or_create_by!(unit: unit, tenant: tenant) do |l|
  l.start_date = Date.current.beginning_of_month
  l.end_date = 1.year.from_now.to_date
  l.rent_amount = 1650
  l.deposit_amount = 1650
  l.status = :active
end

work_order = WorkOrder.find_or_create_by!(unit: unit, created_by: tenant, title: "Kitchen faucet leak") do |wo|
  wo.lease = lease
  wo.description = "The kitchen faucet drips constantly."
  wo.priority = :high
  wo.status = :open
end

WorkOrderAssignment.find_or_create_by!(work_order: work_order, contractor: contractor) do |a|
  a.status = :accepted
  a.scheduled_at = 2.days.from_now
end

conversation = Conversation.for_work_order!(work_order)
if conversation.messages.empty?
  conversation.messages.create!(author: tenant, body: "Hi, when can someone take a look at the faucet?")
  conversation.messages.create!(author: contractor, body: "I can stop by in a couple of days.")
end

puts "Seeded users (password: password123):"
[ admin, landlord, tenant, contractor ].each { |u| puts "  #{u.role.ljust(10)} #{u.email}" }
