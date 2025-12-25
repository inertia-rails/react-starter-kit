# frozen_string_literal: true

class Settings::EmailsController < InertiaController
  before_action :set_user

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to_success
    else
      redirect_to settings_email_path, inertia: {errors: @user.errors}
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.permit(:email, :password_challenge).with_defaults(password_challenge: "")
  end

  def redirect_to_success
    if @user.email_previously_changed?
      resend_email_verification
      redirect_to settings_email_path, notice: "Your email has been changed"
    else
      redirect_to settings_email_path
    end
  end

  def resend_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
