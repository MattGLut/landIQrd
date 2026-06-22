module Users
  class RegistrationsController < Devise::RegistrationsController
    SELF_SIGNUP_ROLES = %w[tenant landlord contractor].freeze

    layout :registration_layout

    def new
      build_resource({})
      if params[:invite_token].present?
        @invitation = LeaseInvitation.usable.find_by(token: params[:invite_token])
        resource.email = @invitation.email if @invitation
        resource.role = "tenant"
      end
      respond_with resource
    end

    def create
      build_resource(sign_up_params)
      resource.role = "tenant" if invite_token.present?

      if resource.save
        accept_invitation_if_present(resource)
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    protected

    def after_sign_up_path_for(_resource)
      authenticated_root_path
    end

    def sign_up_params
      permitted = super
      permitted[:role] = "tenant" if invite_token.present?
      permitted[:role] = "tenant" unless SELF_SIGNUP_ROLES.include?(permitted[:role])
      permitted
    end

    def account_update_params
      permitted = super
      permitted.delete(:role)
      permitted
    end

    private

    def invite_token
      params.dig(:user, :invite_token) || params[:invite_token]
    end

    def accept_invitation_if_present(user)
      return if invite_token.blank?

      invitation = LeaseInvitation.usable.find_by(token: invite_token)
      return unless invitation

      invitation.accept!(user)
      Notifications::Deliver.lease_invitation_accepted(invitation, actor: user)
    end

    def registration_layout
      user_signed_in? ? "application" : "auth"
    end
  end
end
