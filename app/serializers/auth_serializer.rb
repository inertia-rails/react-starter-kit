# frozen_string_literal: true

class AuthSerializer < ApplicationSerializer
  one :user
  one :session
end
