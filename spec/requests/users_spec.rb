# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /sign_up" do
    it "returns http success" do
      get sign_up_url
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /sign_up" do
    it "creates a new user and redirects to the root url" do
      expect {
        post sign_up_url, params: {name: "New User", email: "new@example.com", password: "Secret1*3*5*"}
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_url)
    end
  end
end
