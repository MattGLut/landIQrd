Rails.application.config.to_prepare do
  Devise::SessionsController.layout "auth"
  Devise::RegistrationsController.layout "auth"
  Devise::PasswordsController.layout "auth"
  Devise::ConfirmationsController.layout "auth"
  Devise::UnlocksController.layout "auth"
end
