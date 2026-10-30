# frozen_string_literal: true

module Seeds
  # Demo data for the request-for-proposals marketplace: contractor trades and
  # service areas, plus a handful of jobs in different stages.
  #
  # Standalone and idempotent: looks everything up by email so it also works
  # when the bulk seed is skipped.
  module Marketplace
    CONTRACTOR_PROFILES = {
      "contractor@propman.test" => { trades: %w[general painting roofing plumbing], city: "Austin" },
      "contractor2@propman.test" => { trades: %w[electrical], city: "Austin" },
      "contractor3@propman.test" => { trades: %w[hvac], city: "Round Rock" },
      "contractor4@propman.test" => { trades: %w[general roofing painting concrete], city: "Austin" },
      "contractor5@propman.test" => { trades: %w[general roofing], city: "Dripping Springs" },
      "contractor6@propman.test" => { trades: %w[general painting roofing], city: "Austin" },
      "contractor7@propman.test" => { trades: %w[landscaping concrete general], city: "Austin" },
      "contractor8@propman.test" => { trades: %w[electrical general], city: "Round Rock" }
    }.freeze

    module_function

    def seed!
      Support.log "Seeding marketplace jobs…"
      assign_trades!
      return if Job.exists?

      landlord = User.find_by(email: "landlord@propman.test")
      property = landlord && landlord.properties.joins(:units).distinct.order(:id).first
      return unless property

      seed_open_roof_job(landlord, property)
      seed_open_painting_job(landlord, property)
      seed_awarded_concrete_job(landlord, property)
      seed_draft_landscaping_job(landlord, property)
    end

    def assign_trades!
      CONTRACTOR_PROFILES.each do |email, profile|
        user = User.find_by(email: email)
        next unless user

        user.update!(
          trades: profile[:trades],
          service_city: profile[:city],
          service_state: "TX",
          service_radius_miles: 50,
          notify_matching_jobs: true
        )
      end
    end

    # Walkthrough required, three proposals already in, the fixture contractor
    # has NOT bid yet so the demo can do it live.
    def seed_open_roof_job(landlord, property)
      job = build_job(
        landlord, property,
        title: "Roof repair after storm damage",
        description: "Shingles lifted on the north slope and a leak above the upstairs bedroom. " \
                     "Need an assessment and repair quote, including flashing around the chimney.",
        trades: %w[roofing general],
        walkthrough_required: true,
        slot_capacity: 3
      )
      slots = add_slots(job, days: [ 3, 4 ], hours: [ 9, 13 ])
      job.publish!

      { "contractor4@propman.test" => [ 4850, "Replace damaged shingles on the north slope, new flashing at chimney, seal and clean up.", 4, 3 ],
        "contractor6@propman.test" => [ 5200, "Full north slope re-shingle with ice-and-water shield and ridge vent inspection.", 7, 2 ],
        "contractor5@propman.test" => [ 4300, "Spot repair of lifted shingles and chimney flashing; leak test after completion.", 10, 1 ] }.each do |email, (amount, scope, start_in, duration_index)|
        contractor = User.find_by(email: email)
        next unless contractor

        book!(slots.first, contractor)
        job.proposals.create!(
          contractor: contractor,
          amount: amount,
          scope: scope,
          exclusions: "Interior drywall repair and painting.",
          earliest_start: Date.current + start_in,
          estimated_duration_days: Proposal::DURATION_OPTIONS.values.fetch(duration_index)
        )
      end
    end

    def seed_open_painting_job(landlord, property)
      job = build_job(
        landlord, property,
        title: "Exterior repaint - two story",
        description: "Pressure wash, scrape, prime and two coats of paint on the exterior trim and siding.",
        trades: %w[painting],
        walkthrough_required: false,
        slot_capacity: 2
      )
      add_slots(job, days: [ 5 ], hours: [ 10, 14 ])
      job.publish!
    end

    def seed_awarded_concrete_job(landlord, property)
      job = build_job(
        landlord, property,
        title: "Repair cracked driveway apron",
        description: "Remove and replace a cracked 10x12 concrete apron at the street.",
        trades: %w[concrete],
        walkthrough_required: false
      )
      job.publish!
      contractor = User.find_by(email: "contractor7@propman.test")
      return unless contractor

      proposal = job.proposals.create!(
        contractor: contractor,
        amount: 3200,
        scope: "Demo and haul away old concrete, form, pour and finish a 4-inch reinforced apron.",
        earliest_start: Date.current + 6,
        estimated_duration_days: 3
      )
      Jobs::Award.call(job: job, proposal: proposal, awarded_by: landlord)
    end

    def seed_draft_landscaping_job(landlord, property)
      build_job(
        landlord, property,
        title: "Spring landscaping cleanup",
        description: "",
        trades: %w[landscaping],
        walkthrough_required: false
      )
    end

    def build_job(landlord, property, attrs)
      Job.create!(attrs.merge(property: property, created_by: landlord, proposal_deadline: Date.current + 14))
    end

    # Creates future slots at the given hours (job-local) on each offset day.
    def add_slots(job, days:, hours:)
      zone = ActiveSupport::TimeZone[job.timezone]
      days.flat_map do |offset|
        hours.map do |hour|
          date = Date.current + offset
          starts = zone.local(date.year, date.month, date.day, hour)
          job.walkthrough_slots.create!(starts_at: starts, ends_at: starts + 1.hour, capacity: job.slot_capacity)
        end
      end
    end

    def book!(slot, contractor)
      WalkthroughBooking.create!(walkthrough_slot: slot, contractor: contractor)
    end
  end
end
