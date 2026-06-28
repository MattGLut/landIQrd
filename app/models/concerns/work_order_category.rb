module WorkOrderCategory
  extend ActiveSupport::Concern

  CATEGORIES = {
    plumbing: "plumbing",
    electrical: "electrical",
    hvac: "hvac",
    appliance: "appliance",
    pest: "pest",
    general: "general",
    other: "other",
    fire_safety: "fire_safety",
    signage: "signage",
    accessibility: "accessibility",
    structural: "structural",
    site_maintenance: "site_maintenance",
    fencing: "fencing",
    utilities: "utilities",
    grading: "grading",
    environmental: "environmental"
  }.freeze

  BASE_CATEGORIES = %w[plumbing electrical hvac appliance pest general other].freeze
  COMMERCIAL_CATEGORIES = %w[fire_safety signage accessibility structural].freeze
  UNDEVELOPED_CATEGORIES = %w[site_maintenance fencing utilities grading environmental].freeze

  class_methods do
    def categories_for(unit)
      keys = BASE_CATEGORIES.dup
      case unit&.effective_type
      when "commercial"
        keys.concat(COMMERCIAL_CATEGORIES)
      when "undeveloped"
        keys.concat(UNDEVELOPED_CATEGORIES)
      end
      keys
    end

    def category_options_for(unit)
      categories_for(unit).map { |key| [ key.titleize, key ] }
    end

    def all_category_options
      CATEGORIES.keys.map { |key| [ key.to_s.titleize, key.to_s ] }
    end
  end
end
