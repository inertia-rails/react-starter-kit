# frozen_string_literal: true

class Settings::SessionsController < InertiaController
  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end
end
