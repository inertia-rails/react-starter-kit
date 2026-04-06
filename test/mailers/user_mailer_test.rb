# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "password_reset" do
    user = users(:one)
    mail = UserMailer.with(user: user).password_reset

    assert_equal "Reset your password", mail.subject
    assert_equal [user.email], mail.to
  end

  test "email_verification" do
    user = users(:one)
    mail = UserMailer.with(user: user).email_verification

    assert_equal "Verify your email", mail.subject
    assert_equal [user.email], mail.to
  end
end
