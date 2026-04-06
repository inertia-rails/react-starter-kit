# frozen_string_literal: true

require "test_helper"

class Identity::EmailVerificationsTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @user.update!(verified: false)
    sign_in_as @user
  end

  test "POST /identity/email_verification sends verification email" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, args: ["UserMailer", "email_verification", "deliver_now", {params: {user: @user}, args: []}]) do
      post identity_email_verification_url
    end

    assert_redirected_to root_url
  end

  test "GET /identity/email_verification with valid token verifies email" do
    sid = @user.generate_token_for(:email_verification)

    get identity_email_verification_url(sid: sid, email: @user.email)
    assert_redirected_to root_url
  end

  test "GET /identity/email_verification with expired token shows error" do
    sid = @user.generate_token_for(:email_verification)

    travel 3.days

    get identity_email_verification_url(sid: sid, email: @user.email)
    assert_redirected_to settings_email_path
    assert_equal "That email verification link is invalid", flash[:alert]
  end
end
