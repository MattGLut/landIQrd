class PropertyFeatureCatalog
  Definition = Struct.new(:key, :label, :data_type, :options, :required, keyword_init: true) do
    def initialize(key:, label:, data_type:, options: nil, required: false)
      super
    end
  end

  PROPERTY_TYPES = %i[residential commercial undeveloped].freeze

  DEFINITIONS = {
    residential: {
      property: [
        Definition.new(key: "parking", label: "Parking", data_type: :enum, options: %w[none street dedicated garage]),
        Definition.new(key: "laundry", label: "Laundry", data_type: :enum, options: %w[none shared in_unit]),
        Definition.new(key: "pool", label: "Pool", data_type: :boolean),
        Definition.new(key: "pet_policy", label: "Pet policy", data_type: :enum, options: %w[no yes cats_only])
      ],
      unit: [
        Definition.new(key: "central_ac", label: "Central A/C", data_type: :boolean),
        Definition.new(key: "washer_dryer", label: "Washer / dryer", data_type: :boolean),
        Definition.new(key: "furnished", label: "Furnished", data_type: :boolean),
        Definition.new(key: "balcony", label: "Balcony", data_type: :boolean)
      ]
    },
    commercial: {
      property: [
        Definition.new(key: "elevator", label: "Elevator", data_type: :boolean),
        Definition.new(key: "sprinkler_system", label: "Sprinkler system", data_type: :boolean),
        Definition.new(key: "ada_accessible", label: "ADA accessible", data_type: :boolean),
        Definition.new(key: "shared_loading", label: "Shared loading area", data_type: :boolean)
      ],
      unit: [
        Definition.new(key: "use_class", label: "Use class", data_type: :enum, options: %w[retail office warehouse restaurant], required: true),
        Definition.new(key: "parking_spaces", label: "Parking spaces", data_type: :integer),
        Definition.new(key: "loading_dock", label: "Loading dock", data_type: :boolean),
        Definition.new(key: "ceiling_height_ft", label: "Ceiling height (ft)", data_type: :decimal),
        Definition.new(key: "restroom_count", label: "Restrooms", data_type: :integer)
      ]
    },
    undeveloped: {
      property: [
        Definition.new(key: "road_frontage_ft", label: "Road frontage (ft)", data_type: :integer),
        Definition.new(key: "fenced", label: "Fenced", data_type: :boolean),
        Definition.new(key: "easement_notes", label: "Easement notes", data_type: :string)
      ],
      unit: [
        Definition.new(key: "zoning", label: "Zoning", data_type: :string),
        Definition.new(key: "water_hookup", label: "Water hookup", data_type: :boolean),
        Definition.new(key: "sewer_hookup", label: "Sewer hookup", data_type: :boolean),
        Definition.new(key: "electric_hookup", label: "Electric hookup", data_type: :boolean),
        Definition.new(key: "gas_hookup", label: "Gas hookup", data_type: :boolean),
        Definition.new(key: "topography", label: "Topography", data_type: :enum, options: %w[flat sloped wooded]),
        Definition.new(key: "flood_zone", label: "Flood zone", data_type: :boolean)
      ]
    }
  }.freeze

  class << self
    def definitions_for(type, scope:)
      DEFINITIONS.dig(type.to_sym, scope.to_sym) || []
    end

    def definition(type, scope, key)
      definitions_for(type, scope: scope).find { |definition| definition.key == key.to_s }
    end

    def keys_for(type, scope:)
      definitions_for(type, scope: scope).map(&:key)
    end

    def all_keys_for(scope)
      PROPERTY_TYPES.flat_map { |type| keys_for(type, scope: scope) }.uniq
    end

    def type_label(type)
      type.to_s.humanize
    end
  end
end
