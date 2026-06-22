module Users
  class RegistrationsController < Devise::RegistrationsController
    SELF_SIGNUP_ROLES = %w[tenant landlord contractor].freeze

    protected

    # Prevent privilege escalation: anyone self-registering as "admin"
    # (or any unknown role) is forced down to "tenant".
    def sign_up_params
      permitted = super
      permitted[:role] = "tenant" unless SELF_SIGNUP_ROLES.include?(permitted[:role])
      permitted
    end

    def account_update_params
      permitted = super
      permitted.delete(:role) # role changes only via admin tools
      permitted
    end
  end
end
