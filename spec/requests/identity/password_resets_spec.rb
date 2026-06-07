# frozen_string_literal: true

require "rails_helper"
include ActiveSupport::Testing::TimeHelpers

RSpec.describe "Identity::PasswordResets", type: :request do
  fixtures :users
  let(:user) { users(:one) }

  describe "GET /new" do
    it "returns http success" do
      get new_identity_password_reset_url
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      sid = user.generate_token_for(:password_reset)
      get edit_identity_password_reset_url(sid:)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid email" do
      it "sends a password reset email" do
        expect {
          post identity_password_reset_url, params: {email: user.email}
        }.to have_enqueued_email(UserMailer, :password_reset).with(params: {user:}, args: [])
        expect(response).to redirect_to(sign_in_url)
      end
    end

    context "with nonexistent email" do
      it "does not send a password reset email" do
        expect {
          post identity_password_reset_url, params: {email: "invalid_email@hey.com"}
        }.not_to have_enqueued_email(UserMailer, :password_reset)
        expect(response).to redirect_to(new_identity_password_reset_url)
        expect(flash[:alert]).to eq("You can't reset your password until you verify your email")
      end
    end

    context "with unverified email" do
      before { user.update!(verified: false) }

      it "does not send a password reset email" do
        expect {
          post identity_password_reset_url, params: {email: user.email}
        }.not_to have_enqueued_email(UserMailer, :password_reset)
        expect(response).to redirect_to(new_identity_password_reset_url)
        expect(flash[:alert]).to eq("You can't reset your password until you verify your email")
      end
    end
  end

  describe "PATCH /update" do
    context "with valid token" do
      it "updates the password" do
        sid = user.generate_token_for(:password_reset)
        patch identity_password_reset_url, params: {sid:, password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}
        expect(response).to redirect_to(sign_in_url)
      end
    end

    context "with expired token" do
      it "does not update the password" do
        sid = user.generate_token_for(:password_reset)
        travel 30.minutes

        patch identity_password_reset_url, params: {sid:, password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}
        expect(response).to redirect_to(new_identity_password_reset_url)
        expect(flash[:alert]).to eq("That password reset link is invalid")
      end
    end
  end
end
