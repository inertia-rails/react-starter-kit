# frozen_string_literal: true

require "rails_helper"
include ActiveSupport::Testing::TimeHelpers

RSpec.describe "Identity::EmailVerifications", type: :request do
  fixtures :users
  let(:user) { users(:one) }

  before do
    user.update!(verified: false)
    sign_in user
  end

  describe "POST /identity/email_verification" do
    it "sends a verification email" do
      expect {
        post identity_email_verification_url
      }.to have_enqueued_email(UserMailer, :email_verification).with(params: {user:}, args: [])

      expect(response).to redirect_to(root_url)
    end
  end

  describe "GET /identity/email_verification" do
    context "with valid token" do
      it "verifies the email" do
        sid = user.generate_token_for(:email_verification)

        get identity_email_verification_url(sid:, email: user.email)
        expect(response).to redirect_to(root_url)
      end
    end

    context "with expired token" do
      it "does not verify the email" do
        sid = user.generate_token_for(:email_verification)

        travel 3.days

        get identity_email_verification_url(sid:, email: user.email)
        expect(response).to redirect_to(settings_email_path)
        expect(flash[:alert]).to eq("That email verification link is invalid")
      end
    end
  end
end
