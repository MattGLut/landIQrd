module Contractor
  class BusinessProfilesController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      if @user.update(business_profile_params)
        redirect_to edit_contractor_business_profile_path, notice: "Business profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def business_profile_params
      params.require(:user).permit(:company_name, :phone, :website_url)
    end
  end
end
