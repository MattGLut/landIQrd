module Contractor
  class BaseController < ApplicationController
    before_action :require_contractor!

    layout "application"

    private

    def require_contractor!
      return if current_user.contractor?

      redirect_to root_path, alert: "You are not authorized to perform that action."
    end
  end
end
