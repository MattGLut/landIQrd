# frozen_string_literal: true

module Seeds
  module Accounts
    module_function

    def seed!
      Support.log "Seeding accounts…"

      admin = Support.upsert_user(
        "admin@propman.test",
        role: :admin,
        first_name: "Avery",
        last_name: "Admin"
      )

      fixture_landlord = Support.upsert_user(
        "landlord@propman.test",
        role: :landlord,
        first_name: "Lana",
        last_name: "Lord",
        company_name: "Lord Property Group"
      )

      fixture_tenant = Support.upsert_user(
        "tenant@propman.test",
        role: :tenant,
        first_name: "Toni",
        last_name: "Tenant"
      )

      fixture_contractor = Support.upsert_user(
        "contractor@propman.test",
        role: :contractor,
        first_name: "Casey",
        last_name: "Contractor",
        company_name: "FixIt Co"
      )

      Support.state[:admin] = admin
      Support.state[:fixture_landlord] = fixture_landlord
      Support.state[:fixture_tenant] = fixture_tenant
      Support.state[:fixture_contractor] = fixture_contractor
      Support.state[:landlords] = [ fixture_landlord ]

      5.times do |index|
        landlord = Support.upsert_user(
          "landlord#{index + 2}@propman.test",
          role: :landlord,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          company_name: "#{Faker::Address.community} Properties"
        )
        Support.state[:landlords] << landlord
      end

      44.times do |index|
        tenant = Support.upsert_user(
          "tenant#{index + 2}@propman.test",
          role: :tenant,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name
        )
        Support.state[:tenants] << tenant
      end
      Support.state[:tenants].unshift(fixture_tenant)

      land_tenant = Support.upsert_user(
        "landtenant@propman.test",
        role: :tenant,
        first_name: "Pat",
        last_name: "Parcel"
      )
      Support.state[:tenants] << land_tenant unless Support.state[:tenants].include?(land_tenant)

      contractor_names = [
        [ "Riley", "Reyes", "Reyes Plumbing" ],
        [ "Jordan", "Sparks", "Sparks Electric" ],
        [ "Morgan", "Hayes", "Hayes HVAC" ],
        [ "Alex", "Brooks", "Brooks General Contracting" ],
        [ "Sam", "Rivera", "Rivera Pest Control" ],
        [ "Drew", "Nguyen", "Nguyen Commercial Services" ],
        [ "Jamie", "Cole", "Cole Site Works" ],
        [ "Taylor", "Grant", "Grant Fire & Safety" ]
      ]

      Support.state[:contractors] = [ fixture_contractor ]
      contractor_names.drop(1).each_with_index do |(first, last, company), index|
        contractor = Support.upsert_user(
          "contractor#{index + 2}@propman.test",
          role: :contractor,
          first_name: first,
          last_name: last,
          company_name: company
        )
        Support.state[:contractors] << contractor
      end
    end
  end
end
