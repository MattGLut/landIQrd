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
    roofing: "roofing",
    painting: "painting",
    landscaping: "landscaping",
    concrete: "concrete",
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

  # Keep in sync with app/javascript/controllers/work_order_category_controller.js
  BASE_CATEGORIES = %w[
    plumbing electrical hvac appliance pest general other roofing painting landscaping concrete
  ].freeze
  COMMERCIAL_CATEGORIES = %w[fire_safety signage accessibility structural].freeze
  UNDEVELOPED_CATEGORIES = %w[site_maintenance fencing utilities grading environmental].freeze

  # Trades offered in the proposal marketplace (job posting and contractor profile pickers).
  MARKETPLACE_TRADES = %w[roofing painting electrical plumbing hvac landscaping concrete general].freeze

  TRADE_LABELS = { "general" => "General contractor", "hvac" => "HVAC" }.freeze

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

    def trade_label(key)
      TRADE_LABELS.fetch(key.to_s) { key.to_s.titleize }
    end

    def marketplace_trade_options
      MARKETPLACE_TRADES.map { |key| [ trade_label(key), key ] }
    end
  end
end
