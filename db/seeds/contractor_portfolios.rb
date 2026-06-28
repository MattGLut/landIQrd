# frozen_string_literal: true

module Seeds
  module ContractorPortfolios
    FIXTURE_PORTFOLIO = {
      "contractor@propman.test" => {
        website_url: "https://fixitco.example.com",
        phone: "512-555-0100",
        items: [
          {
            title: "Multi-unit repipe",
            description: "Replaced aging galvanized lines across a 12-unit building.",
            category: "plumbing",
            position: 0
          },
          {
            title: "Emergency leak repair",
            description: "After-hours slab leak isolation and restoration.",
            category: "plumbing",
            position: 1
          },
          {
            title: "Common area refresh",
            description: "Drywall, paint, and trim work in shared hallways.",
            category: "general",
            position: 2
          }
        ]
      }
    }.freeze

    GENERATED_CONTRACTORS = {
      "Reyes Plumbing" => {
        website_url: "https://reyesplumbing.example.com",
        categories: %w[plumbing]
      },
      "Sparks Electric" => {
        website_url: "https://sparkselectric.example.com",
        categories: %w[electrical]
      },
      "Hayes HVAC" => {
        website_url: "https://hayeshvac.example.com",
        categories: %w[hvac]
      },
      "Brooks General Contracting" => {
        website_url: "https://brooksgc.example.com",
        categories: %w[general structural]
      },
      "Rivera Pest Control" => {
        website_url: "https://riverapest.example.com",
        categories: %w[pest]
      },
      "Nguyen Commercial Services" => {
        website_url: "https://nguyencommercial.example.com",
        categories: %w[fire_safety accessibility signage]
      },
      "Cole Site Works" => {
        website_url: "https://colesiteworks.example.com",
        categories: %w[site_maintenance grading fencing utilities]
      },
      "Grant Fire & Safety" => {
        website_url: "https://grantfire.example.com",
        categories: %w[fire_safety]
      }
    }.freeze

    PORTFOLIO_TITLES = {
      "plumbing" => "Residential plumbing upgrade",
      "electrical" => "Panel and outlet modernization",
      "hvac" => "Rooftop unit replacement",
      "pest" => "Multi-building pest treatment",
      "general" => "Interior repair and finish work",
      "structural" => "Load-bearing wall reinforcement",
      "fire_safety" => "Fire extinguisher and exit compliance",
      "accessibility" => "Ramp and door hardware upgrade",
      "signage" => "Monument sign replacement",
      "site_maintenance" => "Lot clearing and drainage prep",
      "grading" => "Drainage swale regrade",
      "fencing" => "Perimeter fence rebuild",
      "utilities" => "Utility trench and conduit install"
    }.freeze

    module_function

    def seed!
      Support.log "Seeding contractor profiles and portfolios…"

      contractors = Support.state[:contractors].presence || User.contractor.order(:id).to_a
      contractors.each do |contractor|
        seed_contractor!(contractor)
      end
    end

    def seed_contractor!(contractor)
      profile = profile_for(contractor)
      contractor.update!(
        phone: profile[:phone] || contractor.phone.presence || "512-555-#{1000 + contractor.id.to_i % 9000}",
        website_url: profile[:website_url]
      )

      portfolio_items_for(contractor, profile).each do |item_attrs|
        upsert_portfolio_item!(contractor, item_attrs)
      end
    end

    def portfolio_items_for(contractor, profile)
      return profile[:items] if profile[:items].present?

      generated_items_for(contractor, profile[:categories] || %w[general])
    end

    def profile_for(contractor)
      fixture = FIXTURE_PORTFOLIO[contractor.email]
      return fixture if fixture

      generated = GENERATED_CONTRACTORS[contractor.company_name]
      if generated
        return {
          website_url: generated[:website_url],
          categories: generated[:categories]
        }
      end

      {
        website_url: "https://#{(contractor.company_name.presence || contractor.display_name).parameterize}.example.com",
        categories: %w[general]
      }
    end

    def generated_items_for(contractor, categories)
      categories.map.with_index do |category, index|
        {
          title: PORTFOLIO_TITLES.fetch(category, "#{category.titleize} project"),
          description: "Sample #{category.humanize.downcase} work completed by #{contractor.company_name}.",
          category: category,
          position: index
        }
      end
    end

    def upsert_portfolio_item!(contractor, attrs)
      item = ContractorPortfolioItem.find_or_initialize_by(contractor: contractor, title: attrs[:title])
      item.assign_attributes(attrs.except(:title))
      attach_sample_photo!(item) unless item.photos.attached?
      item.save!
      item
    end

    def attach_sample_photo!(item)
      item.photos.attach(
        io: StringIO.new(sample_png_bytes),
        filename: "#{item.category}-portfolio.png",
        content_type: "image/png"
      )
    end

    def sample_png_bytes
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")
    end
  end
end
