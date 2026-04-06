# frozen_string_literal: true

require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest
  test "GET /sign_up returns success" do
    get sign_up_url
    assert_response :success
  end

  test "POST /sign_up creates a new user" do
    assert_difference "User.count", 1 do
      post sign_up_url, params: {
        email: "newuser@example.com",
        name: "New User",
        password: "Secret1*3*5*",
        password_confirmation: "Secret1*3*5*"
      }
    end

    assert_redirected_to dashboard_url
  end
end
