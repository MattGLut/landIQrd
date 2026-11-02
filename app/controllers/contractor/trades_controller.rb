module Contractor
  # "My trades": choose trades, service area, and see matching open jobs.
  class TradesController < BaseController
    skip_after_action :verify_authorized

    def show
      @user = current_user
      load_opportunities
    end

    def update
      @user = current_user

      if @user.update(trades_params)
        redirect_to contractor_trades_path, notice: "Trade preferences saved."
      else
        load_opportunities
        render :show, status: :unprocessable_entity
      end
    end

    private

    def trades_params
      params.require(:user).permit(:service_city, :service_state, :service_radius_miles, :notify_matching_jobs, trades: [])
    end

    def load_opportunities
      @opportunities = policy_scope(Job)
                         .accepting_proposals
                         .matching_trades(@user.trades)
                         .includes(:property, :walkthrough_slots, attachments_attachments: :blob)
                         .recent
                         .select { |job| in_service_area?(job) }
    end

    def in_service_area?(job)
      state = @user.service_state.to_s.strip.downcase
      state.blank? || job.property.state.to_s.strip.downcase.in?([ "", state ])
    end
  end
end
