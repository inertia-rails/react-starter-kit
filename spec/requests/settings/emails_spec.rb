# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Emails", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in_as user
  end

  describe "GET /edit" do
    it "returns http success" do
      get settings_email_url
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    context "with valid password challenge" do
      it "updates the email and redirects to the root url" do
        patch settings_email_url, params: {email: "new_email@hey.com", password_challenge: "Secret1*3*5*"}
        expect(response).to redirect_to(settings_email_url)
        expect(flash[:notice]).to eq("Your email has been changed")
      end
    end

    context "with invalid password challenge" do
      it "does not update the email and returns unprocessable entity" do
        patch settings_email_url, params: {email: "new_email@hey.com", password_challenge: "SecretWrong1*3"}
        expect(response).to redirect_to(settings_email_url)
        expect(session[:inertia_errors]).to eq(password_challenge: ["is invalid"])
      end
    end
  end
end
