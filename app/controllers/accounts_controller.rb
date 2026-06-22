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

  private

  def account_params
    params.require(:user).permit(:preferred_name, :avatar, :remove_avatar)
  end
end
