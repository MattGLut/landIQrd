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
  p.property_type = :residential
  p.features = { "parking" => "dedicated", "laundry" => "shared" }
end

unit = Unit.find_or_create_by!(property: property, label: "Apt 1A") do |u|
  u.bedrooms = 2
  u.bathrooms = 1.0
  u.square_feet = 850
  u.features = { "central_ac" => true, "washer_dryer" => true }
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

commercial_property = Property.find_or_create_by!(landlord: landlord, name: "Riverside Retail") do |p|
  p.address_line1 = "400 Riverside Dr"
  p.city = "Austin"
  p.state = "TX"
  p.postal_code = "78704"
  p.property_type = :commercial
  p.features = { "ada_accessible" => true, "shared_loading" => true }
end

commercial_unit = Unit.find_or_create_by!(property: commercial_property, label: "Suite 100") do |u|
  u.square_feet = 1200
  u.features = { "use_class" => "retail", "parking_spaces" => 4, "loading_dock" => false }
end

land_tenant = upsert_user("landtenant@propman.test", role: :tenant, first_name: "Pat", last_name: "Parcel")

land_property = Property.find_or_create_by!(landlord: landlord, name: "Hill Country Parcel") do |p|
  p.address_line1 = "County Road 101"
  p.city = "Dripping Springs"
  p.state = "TX"
  p.postal_code = "78620"
  p.property_type = :undeveloped
  p.features = { "road_frontage_ft" => 250, "fenced" => true }
end

land_unit = Unit.find_or_create_by!(property: land_property, label: "Lot A") do |u|
  u.acreage = 2.5
  u.features = {
    "zoning" => "R-1",
    "water_hookup" => true,
    "sewer_hookup" => false,
    "electric_hookup" => true,
    "gas_hookup" => false
  }
end

land_lease = Lease.find_or_create_by!(unit: land_unit, tenant: land_tenant) do |l|
  l.start_date = Date.current.beginning_of_month
  l.end_date = 2.years.from_now.to_date
  l.rent_amount = 800
  l.deposit_amount = 800
  l.status = :active
end

land_work_order = WorkOrder.find_or_create_by!(unit: land_unit, created_by: land_tenant, title: "Clear brush along fence line") do |wo|
  wo.lease = land_lease
  wo.description = "Brush is encroaching on the north fence."
  wo.priority = :medium
  wo.status = :open
  wo.category = :site_maintenance
end

puts "Seeded users (password: password123):"
[ admin, landlord, tenant, contractor, land_tenant ].each { |u| puts "  #{u.role.ljust(10)} #{u.email}" }
