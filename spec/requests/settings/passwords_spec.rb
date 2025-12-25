# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Passwords", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in_as user
  end

  describe "GET /settings/password" do
    it "returns http success" do
      get settings_password_url
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /settings/password" do
    context "with valid password challenge" do
      it "updates the password and redirects to the dashboard url" do
        patch settings_password_url, params: {password_challenge: "Secret1*3*5*", password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}
        expect(response).to redirect_to(settings_password_path)
        expect(flash[:notice]).to eq("Your password has been changed")
      end
    end

    context "with invalid password challenge" do
      it "does not update the password and returns redirect" do
        patch settings_password_url, params: {password_challenge: "SecretWrong1*3", password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*"}
        expect(response).to redirect_to(settings_password_path)
        expect(session[:inertia_errors]).to eq(
          password_challenge: ["is invalid"],
        )
      end
    end
  end
end
