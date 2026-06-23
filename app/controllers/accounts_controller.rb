class AccountsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    redirect_to edit_account_path
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.avatar.purge if params.dig(:user, :remove_avatar) == "1"
    if @user.update(account_params.except(:remove_avatar))
      redirect_to edit_account_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def notifications
    @user = current_user
  end

  def update_notifications
    @user = current_user
    if @user.update(email_notification_preferences: notification_preferences_params)
      respond_to do |format|
        format.html { redirect_to notifications_account_path }
        format.turbo_stream { head :no_content }
      end
    else
      render :notifications, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:preferred_name, :avatar, :remove_avatar)
  end

  def notification_preferences_params
    permitted_keys = @user.applicable_email_notification_types.keys.map(&:to_s)
    raw = params.fetch(:user, {}).fetch(:email_notification_preferences, {}).permit(*permitted_keys)

    permitted_keys.index_with { |key| raw[key] == "1" }
  end
end
