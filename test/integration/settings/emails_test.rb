# frozen_string_literal: true

require "test_helper"

class Settings::EmailsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "GET /edit returns success" do
    get settings_email_url
    assert_response :success
  end

  test "PATCH /update with valid password challenge updates email" do
    patch settings_email_url, params: {
      email: "new_email@hey.com",
      password_challenge: "Secret1*3*5*"
    }
    assert_redirected_to settings_email_url
    assert_equal "Your email has been changed", flash[:notice]
  end

  test "PATCH /update with invalid password challenge shows error" do
    patch settings_email_url, params: {
      email: "new_email@hey.com",
      password_challenge: "SecretWrong1*3"
    }
    assert_redirected_to settings_email_url
    assert_equal(
      {password_challenge: "Password challenge is invalid"},
      session[:inertia_errors]
    )
  end
end
