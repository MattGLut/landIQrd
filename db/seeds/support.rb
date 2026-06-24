# frozen_string_literal: true

module Seeds
  module Support
    FIXTURE_EMAILS = %w[
      admin@propman.test
      landlord@propman.test
      tenant@propman.test
      contractor@propman.test
    ].freeze

    TEXAS_CITIES = [
      [ "Austin", "TX", "78701" ],
      [ "Dallas", "TX", "75201" ],
      [ "Houston", "TX", "77002" ],
      [ "San Antonio", "TX", "78205" ],
      [ "Fort Worth", "TX", "76102" ],
      [ "El Paso", "TX", "79901" ],
      [ "Dripping Springs", "TX", "78620" ],
      [ "Round Rock", "TX", "78664" ]
    ].freeze

    PROPERTY_TYPE_WEIGHTS = { residential: 60, commercial: 25, undeveloped: 15 }.freeze

    WORK_ORDER_STATUSES = %i[
      open open open
      pending_management pending_management
      pending_tenant
      on_hold
      completed completed completed
      cancelled
    ].freeze

    module_function

    def state
      @state ||= {
        landlords: [],
        tenants: [],
        contractors: [],
        properties: [],
        units: [],
        leases: [],
        work_orders: [],
        rng: Random.new(42)
      }
    end

    def reset_state!
      @state = nil
    end

    def rng
      state[:rng]
    end

    def pick(array)
      array[rng.rand(array.length)]
    end

    def weighted_pick(weights)
      total = weights.values.sum
      roll = rng.rand(total)
      weights.each do |key, weight|
        roll -= weight
        return key if roll.negative?
      end
      weights.keys.first
    end

    def already_seeded?
      Property.count >= 20
    end

    def force_reseed?
      ENV["FORCE_SEED"] == "1"
    end

    def demo_seed_allowed?
      !Rails.env.production? || ENV["ALLOW_DEMO_SEED"] == "1"
    end

    def prepare!
      reset_state!
      require "faker"
      Faker::Config.random = rng
      demo_reset! if force_reseed?
    end

    def fake_first_name
      Faker::Name.first_name
    end

    def fake_last_name
      Faker::Name.last_name
    end

    def fake_street_address
      Faker::Address.street_address
    end

    def fake_community_name
      Faker::Address.community
    end

    def silence_side_effects
      previous_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      yield
    ensure
      ActiveJob::Base.queue_adapter = previous_adapter
    end

    def demo_reset!
      puts "FORCE_SEED=1 — clearing demo data…"
      Message.delete_all
      ConversationParticipant.delete_all
      Conversation.delete_all
      WorkOrderEvent.delete_all
      WorkOrderAssignment.delete_all
      WorkOrder.delete_all
      LeaseInvitation.delete_all
      Lease.delete_all
      Unit.delete_all
      Property.delete_all
      User.where.not(email: FIXTURE_EMAILS).delete_all
    end

    def upsert_user(email, role:, **attrs)
      user = User.find_or_initialize_by(email: email)
      user.role = role
      user.password = "password123"
      user.password_confirmation = "password123"
      user.assign_attributes(attrs)
      user.save!
      user
    end

    def build_unit_features(unit_type)
      features = {}
      PropertyFeatureCatalog.definitions_for(unit_type, scope: :unit).each do |definition|
        next if !definition.required && rng.rand > 0.65

        features[definition.key] = sample_feature_value(definition)
      end
      features
    end

    def build_property_features(property_type)
      features = {}
      PropertyFeatureCatalog.definitions_for(property_type, scope: :property).each do |definition|
        next if rng.rand > 0.7

        features[definition.key] = sample_feature_value(definition)
      end
      features.compact
    end

    def sample_feature_value(definition)
      case definition.data_type
      when :boolean
        rng.rand < 0.45
      when :enum
        pick(definition.options)
      when :integer
        rng.rand(1..20)
      when :decimal
        BigDecimal((rng.rand(8..16) + rng.rand).round(1).to_s)
      when :string
        pick(%w[R-1 C-2 MU-LD AG I-1])
      end
    end

    def texas_address
      city, state_abbr, zip = pick(TEXAS_CITIES)
      {
        address_line1: fake_street_address,
        city: city,
        state: state_abbr,
        postal_code: zip
      }
    end

    def unit_count_for(property_type)
      case property_type.to_sym
      when :residential then rng.rand(1..8)
      when :commercial then rng.rand(1..6)
      when :undeveloped then rng.rand(1..3)
      else 1
      end
    end

    def unit_label(property_type, index)
      case property_type.to_sym
      when :residential
        letters = ("A".."Z").to_a
        floor = (index / 4) + 1
        "Apt #{floor}#{letters[index % 4]}"
      when :commercial
        "Suite #{100 + (index * 100)}"
      when :undeveloped
        "Lot #{("A".."Z").to_a[index]}"
      else
        "Unit #{index + 1}"
      end
    end

    def build_unit_attrs(property, property_type, index, override_type: nil)
      effective = override_type || property_type
      attrs = {
        label: unit_label(property_type, index),
        unit_type: override_type,
        features: build_unit_features(effective)
      }

      case effective.to_sym
      when :residential
        attrs.merge!(
          bedrooms: rng.rand(1..4),
          bathrooms: pick([ 1, 1, 1.5, 2, 2.5 ]),
          square_feet: rng.rand(500..1800)
        )
      when :commercial
        attrs.merge!(
          square_feet: rng.rand(800..5000),
          features: attrs[:features].merge("use_class" => pick(%w[retail office warehouse restaurant]))
        )
      when :undeveloped
        attrs.merge!(
          acreage: (rng.rand(1..20) + rng.rand).round(2),
          features: attrs[:features].merge("zoning" => pick(%w[R-1 C-2 MU-LD AG]))
        )
      end

      attrs
    end

    def rent_for(unit)
      case unit.effective_type
      when "residential"
        base = unit.square_feet ? (unit.square_feet * 1.8) : 1200
        (base / 50).round * 50
      when "commercial"
        base = unit.square_feet ? (unit.square_feet * 1.2) : 2000
        (base / 100).round * 100
      when "undeveloped"
        (unit.acreage.to_f * 350).round(-1)
      else
        1000
      end
    end

    def occupancy_scenario(index)
      %i[active active active active active active active
         ended_history ended_history
         draft
         invitation_pending invitation_pending
         vacant vacant].fetch(index % 13)
    end

    WORK_ORDER_COPY = {
      "plumbing" => [ "Leaky kitchen faucet", "Slow drain in bathroom", "Toilet running constantly" ],
      "electrical" => [ "Outlet not working in bedroom", "Breaker keeps tripping", "Light fixture flickering" ],
      "hvac" => [ "AC not cooling", "Heater making loud noise", "Thermostat unresponsive" ],
      "appliance" => [ "Dishwasher not draining", "Oven not heating evenly", "Garbage disposal jammed" ],
      "pest" => [ "Ants in kitchen", "Rodent sighting in storage", "Wasp nest near entrance" ],
      "general" => [ "Loose handrail on stairs", "Sticky front door", "Broken window latch" ],
      "other" => [ "Noise complaint follow-up", "Mailbox key replacement", "Misc repair request" ],
      "fire_safety" => [ "Extinguisher inspection due", "Emergency exit sign out", "Smoke detector chirping" ],
      "signage" => [ "Storefront sign loose", "Wayfinding sign damaged", "Replace faded tenant sign" ],
      "accessibility" => [ "Ramp handrail loose", "Automatic door slow to open", "Accessible parking striping faded" ],
      "structural" => [ "Crack in exterior wall", "Ceiling tile sagging", "Garage door frame shifting" ],
      "site_maintenance" => [ "Clear brush along fence line", "Gravel driveway washout", "Mow overgrown access path" ],
      "fencing" => [ "Broken fence panel", "Gate latch failing", "Replace missing post cap" ],
      "utilities" => [ "Water meter box cover missing", "Exposed conduit near pad", "Irrigation line leak" ],
      "grading" => [ "Standing water after rain", "Erosion near culvert", "Regrade drainage swale" ],
      "environmental" => [ "Standing water pooling", "Suspected drainage issue", "Soil erosion near creek" ]
    }.freeze

    def work_order_title(category)
      pick(WORK_ORDER_COPY.fetch(category.to_s, WORK_ORDER_COPY["general"]))
    end

    def work_order_category_for(unit)
      pick(WorkOrder.categories_for(unit))
    end

    def log(message)
      puts message
    end

    def print_summary
      landlord_count = User.landlord.count
      tenant_count = User.tenant.count
      contractor_count = User.contractor.count

      puts ""
      puts "Demo seed complete (password: password123)"
      puts "  Users:        #{User.count} (#{landlord_count} landlords, #{tenant_count} tenants, #{contractor_count} contractors)"
      puts "  Properties:   #{Property.count}"
      puts "  Units:        #{Unit.count}"
      puts "  Leases:       #{Lease.count} (#{Lease.where(status: :active).count} active)"
      puts "  Invitations:  #{LeaseInvitation.status_pending.count} pending"
      puts "  Work orders:  #{WorkOrder.count}"
      puts "  Assignments:  #{WorkOrderAssignment.count} (#{WorkOrderAssignment.where.not(scheduled_at: nil).count} scheduled)"
      puts "  Conversations:#{Conversation.count}"
      puts ""
      puts "Stable logins:"
      FIXTURE_EMAILS.each { |email| puts "  #{email}" }
      puts ""
      generated_landlords = User.landlord.where.not(email: "landlord@propman.test").limit(2)
      if generated_landlords.any?
        puts "Generated examples:"
        generated_landlords.each { |u| puts "  #{u.email}" }
        puts ""
      end
      puts "Re-run with FORCE_SEED=1 bundle exec rails db:seed to rebuild demo data."
    end

    def print_skipped_summary
      puts "Demo data already present (#{Property.count} properties). Skipping bulk seed."
      puts 'Run FORCE_SEED=1 bundle exec rails db:seed to rebuild (PowerShell: $env:FORCE_SEED = "1"; bundle exec rails db:seed).'
      print_summary
    end
  end
end
