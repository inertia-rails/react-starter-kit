# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Emails", type: :request do
  fixtures :users

  before { sign_in users(:one) }

  describe "GET /settings/email" do
    it "renders the email settings page" do
      get settings_email_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /settings/email" do
    context "with valid password challenge" do
      it "updates the email" do
        patch settings_email_path, params: {
          email: "updated@example.com",
          password_challenge: "Secret1*3*5*"
        }
        expect(response).to redirect_to(settings_email_path)
        expect(flash[:notice]).to eq("Your email has been changed")
        expect(users(:one).reload.email).to eq("updated@example.com")
      end
    end

    context "with invalid password challenge" do
      it "does not update the email and returns inertia errors" do
        patch settings_email_path, params: {
          email: "updated@example.com",
          password_challenge: "wrongpassword"
        }
        expect(response).to redirect_to(settings_email_path)
        expect(session[:inertia_errors]).to eq(password_challenge: ["is invalid"])
        expect(users(:one).reload.email).to eq("one@example.com")
      end
    end
  end
end
