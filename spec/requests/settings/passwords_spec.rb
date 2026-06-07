# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Passwords", type: :request do
  fixtures :users

  before { sign_in users(:one) }

  describe "GET /settings/password" do
    it "renders the password settings page" do
      get settings_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /settings/password" do
    context "with valid password challenge" do
      it "updates the password" do
        patch settings_password_path, params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*",
          password_challenge: "Secret1*3*5*"
        }
        expect(response).to redirect_to(settings_password_path)
        expect(flash[:notice]).to eq("Your password has been changed")
      end
    end

    context "with invalid password challenge" do
      it "does not update the password and returns inertia errors" do
        patch settings_password_path, params: {
          password: "NewPassword1*3*",
          password_confirmation: "NewPassword1*3*",
          password_challenge: "wrongpassword"
        }
        expect(response).to redirect_to(settings_password_path)
        expect(session[:inertia_errors]).to eq(password_challenge: ["is invalid"])
      end
    end
  end
end
