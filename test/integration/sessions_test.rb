# frozen_string_literal: true

require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  test "GET /new returns success" do
    get sign_in_url
    assert_response :success
  end

  test "POST /sign_in with valid credentials redirects to dashboard" do
    user = users(:one)
    post sign_in_url, params: {email: user.email, password: "Secret1*3*5*"}
    assert_redirected_to dashboard_url

    get dashboard_url
    assert_response :success
  end

  test "POST /sign_in with invalid credentials shows error" do
    user = users(:one)
    post sign_in_url, params: {email: user.email, password: "SecretWrong1*3"}
    assert_redirected_to sign_in_url
    assert_equal "That email or password is incorrect", flash[:alert]

    get dashboard_url
    assert_redirected_to sign_in_url
  end

  test "DELETE /sign_out signs out user" do
    user = users(:one)
    sign_in_as user

    delete session_url(user.sessions.last)
    assert_redirected_to settings_sessions_url

    follow_redirect!
    assert_redirected_to sign_in_url
  end
end
