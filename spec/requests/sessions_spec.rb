# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /new" do
    it "returns http success" do
      get sign_in_url
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /sign_in" do
    context "with valid credentials" do
      it "redirects to the root url" do
        post sign_in_url, params: {email: user.email, password: "Secret1*3*5*"}
        expect(response).to redirect_to(dashboard_url)

        get dashboard_url
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid credentials" do
      before { sign_out }

      it "redirects to the sign in url with an alert" do
        post sign_in_url, params: {email: user.email, password: "SecretWrong1*3"}
        expect(response).to redirect_to(sign_in_url)
        expect(flash[:alert]).to eq("That email or password is incorrect")
      end
    end
  end

  describe "DELETE /sign_out" do
    before { sign_in_as user }

    it "signs out the user and redirects to the sign in url" do
      delete session_url(user.sessions.last)
      expect(response).to redirect_to(settings_sessions_url)

      follow_redirect!
      expect(response).to redirect_to(sign_in_url)
    end
  end
end
