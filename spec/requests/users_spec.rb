# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  fixtures :users

  describe "GET /sign_up" do
    it "renders the sign up page" do
      get sign_up_path
      expect(response).to have_http_status(:success)
    end

    it "redirects authenticated users" do
      sign_in users(:one)
      get sign_up_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign_up" do
    it "creates a new user" do
      expect {
        post sign_up_path, params: {
          name: "New User",
          email: "new@example.com",
          password: "Secret1*3*5*",
          password_confirmation: "Secret1*3*5*"
        }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
    end

    it "rejects invalid user" do
      expect {
        post sign_up_path, params: {
          name: "",
          email: "invalid",
          password: "short",
          password_confirmation: "short"
        }
      }.not_to change(User, :count)
      expect(response).to redirect_to(sign_up_path)
    end
  end

  describe "DELETE /users" do
    it "destroys current user with valid password" do
      sign_in users(:one)
      expect {
        delete users_path, params: { password_challenge: "Secret1*3*5*" }
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(root_path)
    end

    it "rejects account deletion with wrong password" do
      sign_in users(:one)
      expect {
        delete users_path, params: { password_challenge: "wrongpassword" }
      }.not_to change(User, :count)
      expect(response).to redirect_to(settings_profile_path)
    end
  end
end
