# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Identity::PasswordResets", type: :request do
  fixtures :users

  describe "GET /identity/password_reset/new" do
    it "renders the forgot password page" do
      get new_identity_password_reset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /identity/password_reset" do
    context "with a verified user" do
      it "sends a password reset email" do
        expect {
          post identity_password_reset_path, params: { email: users(:one).email }
        }.to have_enqueued_mail(UserMailer, :password_reset)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an unverified user" do
      it "does not send a password reset email" do
        users(:one).update!(verified: false)

        expect {
          post identity_password_reset_path, params: { email: users(:one).email }
        }.not_to have_enqueued_mail(UserMailer, :password_reset)
        expect(response).to redirect_to(new_identity_password_reset_path)
        expect(flash[:alert]).to eq("You can't reset your password until you verify your email")
      end
    end

    context "with a nonexistent email" do
      it "does not send a password reset email" do
        expect {
          post identity_password_reset_path, params: { email: "missing@example.com" }
        }.not_to have_enqueued_mail(UserMailer, :password_reset)
        expect(response).to redirect_to(new_identity_password_reset_path)
      end
    end
  end

  describe "GET /identity/password_reset/edit" do
    it "renders the reset page with valid token" do
      sid = users(:one).generate_token_for(:password_reset)
      get edit_identity_password_reset_path(sid: sid)
      expect(response).to have_http_status(:success)
    end

    it "rejects invalid reset token" do
      get edit_identity_password_reset_path(sid: "invalid")
      expect(response).to redirect_to(new_identity_password_reset_path)
    end
  end

  describe "PATCH /identity/password_reset" do
    context "with valid token" do
      it "updates the password" do
        sid = users(:one).generate_token_for(:password_reset)
        patch identity_password_reset_path(sid: sid), params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*"
        }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with expired token" do
      it "rejects the password change" do
        sid = users(:one).generate_token_for(:password_reset)
        travel 30.minutes

        patch identity_password_reset_path(sid: sid), params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*"
        }
        expect(response).to redirect_to(new_identity_password_reset_path)
        expect(flash[:alert]).to eq("That password reset link is invalid")
      end
    end

    context "with mismatched password confirmation" do
      it "rejects the password change" do
        sid = users(:one).generate_token_for(:password_reset)
        patch identity_password_reset_path(sid: sid), params: {
          password: "NewPassword1*3*",
          password_confirmation: "different"
        }
        expect(response).to redirect_to(edit_identity_password_reset_path(sid: sid))
      end
    end
  end
end
