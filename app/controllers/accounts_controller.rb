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

  def update_sms_notifications
    @user = current_user
    return head :not_found unless Notifications::Sms.enabled?
    unless @user.sms_deliverable?
      redirect_to notifications_account_path, alert: "Verify a phone number before choosing text notifications."
      return
    end

    if @user.update(sms_notification_preferences: sms_notification_preferences_params)
      respond_to do |format|
        format.html { redirect_to notifications_account_path }
        format.turbo_stream { head :no_content }
      end
    else
      render :notifications, status: :unprocessable_entity
    end
  end

  def send_phone_verification
    @user = current_user
    return head :not_found unless Notifications::Sms.enabled?

    status = Notifications::PhoneVerification.send_code(
      @user,
      phone: params.dig(:user, :phone),
      consent: params[:sms_consent] == "1"
    )
    case status
    when :sent
      redirect_to notifications_account_path, notice: "We sent a verification code."
    when :consent_required
      redirect_to notifications_account_path, alert: "Agree to receive text messages before we send a code."
    when :invalid
      render :notifications, status: :unprocessable_entity
    else
      redirect_to notifications_account_path, alert: "Text messaging is not available right now."
    end
  end

  def confirm_phone_verification
    @user = current_user
    return head :not_found unless Notifications::Sms.enabled?

    status = Notifications::PhoneVerification.confirm(@user, params[:verification_code])
    case status
    when :confirmed
      redirect_to notifications_account_path, notice: "Phone number verified."
    when :expired
      redirect_to notifications_account_path, alert: "That code expired. Send a new one."
    else
      redirect_to notifications_account_path, alert: "That code did not match."
    end
  end

  private

  def account_params
    params.require(:user).permit(:preferred_name, :avatar, :remove_avatar)
  end

  def notification_preferences_params
    preference_params(:email_notification_preferences)
  end

  def sms_notification_preferences_params
    preference_params(:sms_notification_preferences)
  end

  def preference_params(key)
    permitted_keys = @user.applicable_email_notification_types.keys.map(&:to_s)
    raw = params.fetch(:user, {}).fetch(key, {}).permit(*permitted_keys)

    permitted_keys.index_with { |preference| raw[preference] == "1" }
  end
end
