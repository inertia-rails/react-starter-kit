# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_config default_render: true
  inertia_share auth: {
        user: -> { Current.user.as_json(only: %i[id name email verified created_at updated_at]) },
        session: -> { Current.session.as_json(only: %i[id]) }
      }
end
