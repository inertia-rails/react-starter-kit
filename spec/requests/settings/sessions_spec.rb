# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Sessions", type: :request do
  fixtures :users

  before { sign_in users(:one) }

  describe "GET /settings/sessions" do
    it "renders the sessions index" do
      get settings_sessions_path
      expect(response).to have_http_status(:success)
    end
  end
end
