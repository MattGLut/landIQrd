# frozen_string_literal: true

module Seeds
  module Tenancy
    module_function

    def seed!
      Support.log "Seeding tenancy…"
      tenant_pool = Support.state[:tenants].dup
      tenant_cursor = 0

      Support.state[:units].each_with_index do |unit, index|
        if unit == Support.state[:fixture_unit]
          seed_fixture_lease(unit)
          next
        end

        if unit == Support.state[:land_unit]
          seed_land_lease(unit)
          next
        end

        scenario = Support.occupancy_scenario(index)
        tenant = next_tenant(tenant_pool, tenant_cursor)
        tenant_cursor += 1 if %i[active ended_history draft].include?(scenario)

        case scenario
        when :active
          lease = create_lease(unit, tenant, status: :active)
          Support.state[:leases] << lease
        when :ended_history
          create_lease(
            unit, tenant,
            status: :ended,
            start_date: 2.years.ago.to_date,
            end_date: 1.year.ago.to_date
          )
        when :draft
          lease = create_lease(unit, tenant, status: :draft)
          Support.state[:leases] << lease
        when :invitation_pending
          create_invitation(unit, tenant_pool, tenant_cursor)
          tenant_cursor += 1
        when :vacant
          # intentionally empty
        end
      end
    end

    def seed_fixture_lease(unit)
      tenant = Support.state[:fixture_tenant]
      lease = Lease.find_or_create_by!(unit: unit, tenant: tenant) do |record|
        record.start_date = Date.current.beginning_of_month
        record.end_date = 1.year.from_now.to_date
        record.rent_amount = 1650
        record.deposit_amount = 1650
        record.status = :active
      end
      Support.state[:leases] << lease
      Support.state[:fixture_lease] = lease
    end

    def seed_land_lease(unit)
      tenant = Support.state[:tenants].find { |u| u.email == "landtenant@propman.test" }
      lease = Lease.find_or_create_by!(unit: unit, tenant: tenant) do |record|
        record.start_date = Date.current.beginning_of_month
        record.end_date = 2.years.from_now.to_date
        record.rent_amount = 800
        record.deposit_amount = 800
        record.status = :active
      end
      Support.state[:leases] << lease
      Support.state[:land_lease] = lease
    end

    def next_tenant(pool, cursor)
      pool[cursor % pool.length]
    end

    def create_lease(unit, tenant, status:, start_date: nil, end_date: nil)
      rent = Support.rent_for(unit)
      start_date ||= [ Date.current - Support.rng.rand(30..400), Date.current.beginning_of_month ].min
      end_date ||= start_date + Support.rng.rand(6..24).months

      Lease.create!(
        unit: unit,
        tenant: tenant,
        start_date: start_date,
        end_date: end_date,
        rent_amount: rent,
        deposit_amount: rent,
        status: status
      )
    end

    def create_invitation(unit, tenant_pool, cursor)
      prospect = tenant_pool[cursor % tenant_pool.length]
      rent = Support.rent_for(unit)

      LeaseInvitation.find_or_create_by!(unit: unit, email: prospect.email) do |record|
        record.invited_by = unit.property.landlord
        record.start_date = Date.current + 2.weeks
        record.end_date = Date.current + 1.year
        record.rent_amount = rent
        record.deposit_amount = rent
        record.status = :pending
        record.expires_at = 10.days.from_now
      end
    end
  end
end
