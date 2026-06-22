module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.order(:role, :last_name, :first_name)
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      assign_role(@user)
      if @user.save
        redirect_to admin_user_path(@user), notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      assign_role(@user)
      if @user.update(user_params_for_update)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete your own account."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User deleted."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone, :company_name, :password, :password_confirmation)
    end

    # Role is set explicitly from an allowlist rather than mass-assigned.
    def assign_role(user)
      role = params.dig(:user, :role)
      user.role = role if User.roles.key?(role)
    end

    # On update, only change the password when one was supplied.
    def user_params_for_update
      permitted = user_params
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
  end
end
