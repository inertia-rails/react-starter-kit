# frozen_string_literal: true

require "test_helper"

class Identity::PasswordResetsTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
  end

  test "GET /new returns success" do
    get new_identity_password_reset_url
    assert_response :success
  end

  test "GET /edit returns success" do
    sid = @user.generate_token_for(:password_reset)
    get edit_identity_password_reset_url(sid: sid)
    assert_response :success
  end

  test "POST /create with valid email sends reset email" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, args: ["UserMailer", "password_reset", "deliver_now", {params: {user: @user}, args: []}]) do
      post identity_password_reset_url, params: {email: @user.email}
    end
    assert_redirected_to sign_in_url
  end

  test "POST /create with nonexistent email shows error" do
    assert_no_enqueued_emails do
      post identity_password_reset_url, params: {email: "invalid_email@hey.com"}
    end
    assert_redirected_to new_identity_password_reset_url
    assert_equal "You can't reset your password until you verify your email", flash[:alert]
  end

  test "POST /create with unverified email shows error" do
    @user.update!(verified: false)

    assert_no_enqueued_emails do
      post identity_password_reset_url, params: {email: @user.email}
    end
    assert_redirected_to new_identity_password_reset_url
    assert_equal "You can't reset your password until you verify your email", flash[:alert]
  end

  test "PATCH /update with valid token updates password" do
    sid = @user.generate_token_for(:password_reset)
    patch identity_password_reset_url, params: {
      sid: sid,
      password: "Secret6*4*2*",
      password_confirmation: "Secret6*4*2*"
    }
    assert_redirected_to sign_in_url
  end

  test "PATCH /update with expired token shows error" do
    sid = @user.generate_token_for(:password_reset)
    travel 30.minutes

    patch identity_password_reset_url, params: {
      sid: sid,
      password: "Secret6*4*2*",
      password_confirmation: "Secret6*4*2*"
    }
    assert_redirected_to new_identity_password_reset_url
    assert_equal "That password reset link is invalid", flash[:alert]
  end
end
