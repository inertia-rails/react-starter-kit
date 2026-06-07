# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Identity::EmailVerifications", type: :request do
  fixtures :users

  describe "GET /identity/email_verification" do
    context "with valid token" do
      it "verifies the email" do
        user = users(:one)
        user.update!(verified: false)
        sid = user.generate_token_for(:email_verification)

        get identity_email_verification_path(sid: sid)
        expect(response).to redirect_to(root_path)
        expect(user.reload).to be_verified
      end
    end

    context "with expired token" do
      it "does not verify the email" do
        user = users(:one)
        user.update!(verified: false)
        sid = user.generate_token_for(:email_verification)

        travel 3.days

        get identity_email_verification_path(sid: sid)
        expect(response).to redirect_to(settings_email_path)
        expect(flash[:alert]).to eq("That email verification link is invalid")
        expect(user.reload).not_to be_verified
      end
    end

    context "with invalid token" do
      it "redirects to settings email" do
        get identity_email_verification_path(sid: "invalid")
        expect(response).to redirect_to(settings_email_path)
      end
    end
  end

  describe "POST /identity/email_verification" do
    it "resends the verification email" do
      sign_in users(:one)

      expect {
        post identity_email_verification_path
      }.to have_enqueued_mail(UserMailer, :email_verification)
      expect(response).to be_redirect
    end
  end
end
