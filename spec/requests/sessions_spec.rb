# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  fixtures :users

  describe "GET /sign_in" do
    it "renders the sign in page" do
      get sign_in_path
      expect(response).to have_http_status(:success)
    end

    it "redirects authenticated users" do
      sign_in users(:one)
      get sign_in_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign_in" do
    context "with valid credentials" do
      it "signs in and sets a session cookie" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(dashboard_path)
        expect(cookies[:session_token]).to be_present
      end
    end

    context "with invalid credentials" do
      it "redirects back with an alert" do
        post sign_in_path, params: { email: users(:one).email, password: "wrongpassword" }
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq("That email or password is incorrect")
      end
    end
  end

  describe "DELETE /sessions/:id" do
    it "destroys the session" do
      sign_in users(:one)
      session_record = users(:one).sessions.last
      delete session_path(session_record)
      expect(response).to redirect_to(settings_sessions_path)
    end
  end
end
