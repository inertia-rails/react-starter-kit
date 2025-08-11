# frozen_string_literal: true

class DashboardController < ApplicationController
  skip_before_action :authenticate
  inertia_config default_render: true
  
  # Override the inertia_share for this controller to handle unauthenticated users
  inertia_share flash: -> { flash.to_hash },
      auth: -> {
        if Current.user
          {
            user: Current.user.as_json(only: %i[id name email verified created_at updated_at]),
            session: Current.session.as_json(only: %i[id])
          }
        else
          {
            user: nil,
            session: nil
          }
        end
      }
  
  def index
    # Dashboard renders with or without authentication
    render inertia: 'dashboard/productivity-enhanced'
  end
end
