# frozen_string_literal: true

require "test_helper"

class Settings::PasswordsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "GET /settings/password returns success" do
    get settings_password_url
    assert_response :success
  end

  test "PATCH /settings/password with valid challenge updates password" do
    patch settings_password_url, params: {
      password_challenge: "Secret1*3*5*",
      password: "Secret6*4*2*",
      password_confirmation: "Secret6*4*2*"
    }
    assert_redirected_to settings_password_path
    assert_equal "Your password has been changed", flash[:notice]
  end

  test "PATCH /settings/password with invalid challenge shows error" do
    patch settings_password_url, params: {
      password_challenge: "SecretWrong1*3",
      password: "Secret6*4*2*",
      password_confirmation: "Secret6*4*2*"
    }
    assert_redirected_to settings_password_path
    assert_equal(
      {password_challenge: "Password challenge is invalid"},
      session[:inertia_errors]
    )
  end
end
