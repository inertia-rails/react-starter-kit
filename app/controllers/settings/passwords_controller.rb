# frozen_string_literal: true

class Settings::PasswordsController < InertiaController
  before_action :set_user

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to settings_password_path, notice: "Your password has been changed"
    else
      redirect_to settings_password_path, inertia: {errors: @user.errors}
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.permit(:password, :password_confirmation, :password_challenge).with_defaults(password_challenge: "")
  end
end
