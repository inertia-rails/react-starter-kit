# frozen_string_literal: true

module AuthenticationHelpers
  def self.signed_cookie(name, value)
    cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    cookie_jar.signed[name] = value
    cookie_jar[name]
  end

  module Request
    def sign_in(user)
      session = user.sessions.create!
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
    end

    def sign_out
      cookies[:session_token] = ""
    end
  end

  module System
    def sign_in(user)
      session = user.sessions.create!
      page.driver.set_cookie("session_token", AuthenticationHelpers.signed_cookie(:session_token, session.id))
    end

    def sign_out
      page.driver.set_cookie("session_token", "")
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers::Request, type: :request
  config.include AuthenticationHelpers::System, type: :system
end
