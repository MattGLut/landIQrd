class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  layout :layout_for_request

  after_action :verify_authorized, unless: :pundit_exempt?
  after_action :verify_policy_scoped, if: :verify_index_scope?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  # Devise controllers and personal pages (the dashboard) don't go through Pundit.
  def pundit_exempt?
    devise_controller?
  end

  def verify_index_scope?
    return false if devise_controller?

    action_name == "index"
  end

  def configure_permitted_parameters
    extra = [ :first_name, :last_name, :phone, :company_name, :role ]
    devise_parameter_sanitizer.permit(:sign_up, keys: extra)
    devise_parameter_sanitizer.permit(:account_update, keys: extra)
  end

  def layout_for_request
    devise_controller? ? "auth" : "application"
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform that action."
    redirect_back fallback_location: root_path
  end
end
