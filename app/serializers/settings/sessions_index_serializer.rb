# frozen_string_literal: true

module Settings
  class SessionsIndexSerializer < ApplicationSerializer
    has_many :sessions, with_traits: :details
  end
end
