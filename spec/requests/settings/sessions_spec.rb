# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Sessions", type: :request do
  fixtures :users
  let(:user) { users(:one) }

  describe "GET /index" do
    before { sign_in user }

    it "returns http success" do
      get settings_sessions_url
      expect(response).to have_http_status(:success)
    end
  end
end
