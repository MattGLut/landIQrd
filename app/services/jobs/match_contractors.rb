module Jobs
  # Ranks contractors for a job by trade overlap and service-area fit.
  #
  # Matching is deliberately simple (no geocoding): trades must overlap, and the
  # contractor's service city/state is compared with the property's city/state.
  class MatchContractors
    TRADE_WEIGHT = 70
    CITY_WEIGHT = 30
    STATE_WEIGHT = 15

    Match = Struct.new(:contractor, :score, :shared_trades, :in_area, keyword_init: true) do
      def in_area?
        in_area
      end

      def percent
        score
      end
    end

    def self.call(**args)
      new(**args).call
    end

    def initialize(trades:, city: nil, state: nil, limit: nil)
      @trades = Array(trades).compact_blank.map(&:to_s)
      @city = city.to_s.strip.downcase
      @state = state.to_s.strip.downcase
      @limit = limit
    end

    def call
      return [] if @trades.empty?

      matches = candidates.map { |contractor| build_match(contractor) }
      matches = matches.sort_by { |match| [ -match.score, match.contractor.display_name.to_s ] }
      @limit ? matches.first(@limit) : matches
    end

    private

    def candidates
      User.contractor.where("users.trades && ARRAY[?]::varchar[]", @trades)
    end

    def build_match(contractor)
      shared = contractor.trades & @trades
      trade_score = (TRADE_WEIGHT * shared.size.to_f / @trades.size).round
      location_score = location_score_for(contractor)

      Match.new(
        contractor: contractor,
        score: [ trade_score + location_score, 100 ].min,
        shared_trades: shared,
        in_area: in_area?(contractor)
      )
    end

    def location_score_for(contractor)
      contractor_city = contractor.service_city.to_s.strip.downcase
      contractor_state = contractor.service_state.to_s.strip.downcase

      if contractor_city.present? && contractor_city == @city && (contractor_state.blank? || contractor_state == @state)
        CITY_WEIGHT
      elsif contractor_state.present? && contractor_state == @state
        STATE_WEIGHT
      else
        0
      end
    end

    # Contractors who have not set a service area are treated as available everywhere.
    def in_area?(contractor)
      contractor_state = contractor.service_state.to_s.strip.downcase
      contractor_state.blank? || @state.blank? || contractor_state == @state
    end
  end
end
