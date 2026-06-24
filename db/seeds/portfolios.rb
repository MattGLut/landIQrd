# frozen_string_literal: true

module Seeds
  module Portfolios
    FIXTURE_PROPERTIES = [
      {
        name: "Maple Court",
        property_type: :residential,
        address: { address_line1: "123 Maple St", city: "Austin", state: "TX", postal_code: "78701" },
        features: { "parking" => "dedicated", "laundry" => "shared" },
        units: [
          {
            label: "Apt 1A",
            bedrooms: 2, bathrooms: 1.0, square_feet: 850,
            features: { "central_ac" => true, "washer_dryer" => true },
            fixture: true
          },
          {
            label: "Apt 1B",
            bedrooms: 1, bathrooms: 1.0, square_feet: 650,
            features: { "central_ac" => true, "furnished" => false }
          }
        ]
      },
      {
        name: "Riverside Retail",
        property_type: :commercial,
        address: { address_line1: "400 Riverside Dr", city: "Austin", state: "TX", postal_code: "78704" },
        features: { "ada_accessible" => true, "shared_loading" => true },
        units: [
          {
            label: "Suite 100",
            square_feet: 1200,
            features: { "use_class" => "retail", "parking_spaces" => 4, "loading_dock" => false }
          }
        ]
      },
      {
        name: "Hill Country Parcel",
        property_type: :undeveloped,
        address: { address_line1: "County Road 101", city: "Dripping Springs", state: "TX", postal_code: "78620" },
        features: { "road_frontage_ft" => 250, "fenced" => true },
        units: [
          {
            label: "Lot A",
            acreage: 2.5,
            features: {
              "zoning" => "R-1",
              "water_hookup" => true,
              "sewer_hookup" => false,
              "electric_hookup" => true,
              "gas_hookup" => false
            },
            land_tenant: true
          }
        ]
      },
      {
        name: "Congress Commons",
        property_type: :commercial,
        address: { address_line1: "2100 Congress Ave", city: "Austin", state: "TX", postal_code: "78704" },
        features: { "elevator" => true, "ada_accessible" => true },
        units: [
          {
            label: "Suite 300",
            square_feet: 2200,
            features: { "use_class" => "office", "parking_spaces" => 6, "restroom_count" => 2 }
          },
          {
            label: "Apt 3A",
            unit_type: :residential,
            bedrooms: 2, bathrooms: 2.0, square_feet: 950,
            features: { "central_ac" => true, "balcony" => true },
            override: true
          }
        ]
      }
    ].freeze

    RESIDENTIAL_NAMES = [
      "Oak Terrace", "Pine View", "Cedar Heights", "Birch Lane", "Willow Park",
      "Magnolia Place", "Elm Street Flats", "Juniper Court", "Sycamore Row", "Aspen Grove"
    ].freeze

    COMMERCIAL_NAMES = [
      "Commerce Center", "Market Square", "Industrial Park West", "Lakeside Plaza",
      "Gateway Offices", "Harbor Point Retail"
    ].freeze

    LAND_NAMES = [
      "Brushy Creek Lot", "Ranch Road Parcel", "Valley View Acreage", "Timberline Tract"
    ].freeze

    module_function

    def seed!
      Support.log "Seeding portfolios…"

      Support.state[:landlords].each_with_index do |landlord, landlord_index|
        if landlord_index.zero?
          seed_fixture_portfolio(landlord)
        else
          seed_generated_portfolio(landlord, landlord_index)
        end
      end
    end

    def seed_fixture_portfolio(landlord)
      FIXTURE_PROPERTIES.each do |definition|
        property = upsert_property(landlord, definition)
        definition[:units].each_with_index do |unit_def, unit_index|
          unit = upsert_unit(property, unit_def, unit_index)
          Support.state[:units] << unit
          Support.state[:land_unit] = unit if unit_def[:land_tenant]
        end
      end
    end

    def seed_generated_portfolio(landlord, landlord_index)
      property_count = Support.rng.rand(1..15)
      property_count.times do |property_index|
        property_type = Support.weighted_pick(Support::PROPERTY_TYPE_WEIGHTS)
        name = generated_property_name(property_type, landlord_index, property_index)
        address = Support.texas_address

        property = Property.find_or_create_by!(landlord: landlord, name: name) do |record|
          record.assign_attributes(address)
          record.property_type = property_type
          record.features = Support.build_property_features(property_type)
        end
        Support.state[:properties] << property

        unit_count = Support.unit_count_for(property_type)
        unit_count.times do |unit_index|
          override_type = nil
          if property_type == :commercial && Support.rng.rand < 0.1
            override_type = :residential
          end

          attrs = Support.build_unit_attrs(property, property_type, unit_index, override_type: override_type)
          unit = Unit.find_or_initialize_by(property: property, label: attrs[:label])
          unit.unit_type = attrs[:unit_type] if attrs.key?(:unit_type)
          unit.assign_attributes(attrs.except(:label, :unit_type))
          unit.save!
          Support.state[:units] << unit
        end
      end
    end

    def upsert_property(landlord, definition)
      property = Property.find_or_create_by!(landlord: landlord, name: definition[:name]) do |record|
        record.assign_attributes(definition[:address])
        record.property_type = definition[:property_type]
        record.features = definition[:features]
      end
      Support.state[:properties] << property
      property
    end

    def upsert_unit(property, unit_def, _unit_index)
      attrs = unit_def.except(:label, :fixture, :land_tenant, :override)
      unit = Unit.find_or_initialize_by(property: property, label: unit_def[:label])
      unit.unit_type = attrs[:unit_type] if attrs.key?(:unit_type)
      unit.assign_attributes(attrs.except(:unit_type))
      unit.save!
      Support.state[:fixture_unit] = unit if unit_def[:fixture]
      unit
    end

    def generated_property_name(property_type, landlord_index, property_index)
      pool = case property_type.to_sym
      when :residential then RESIDENTIAL_NAMES
      when :commercial then COMMERCIAL_NAMES
      when :undeveloped then LAND_NAMES
      else RESIDENTIAL_NAMES
      end
      base = pool[(landlord_index + property_index) % pool.length]
      suffix = property_index.positive? ? " #{property_index + 1}" : ""
      "#{base}#{suffix}"
    end
  end
end
