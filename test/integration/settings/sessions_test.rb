# frozen_string_literal: true

require "test_helper"

class Settings::SessionsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "GET /index returns success" do
    get settings_sessions_url
    assert_response :success
  end
end
