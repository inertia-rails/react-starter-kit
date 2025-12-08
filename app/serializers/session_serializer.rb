# frozen_string_literal: true

class SessionSerializer < ApplicationSerializer
  attributes :id

  trait :details do
    attributes :user_agent, :ip_address, :created_at
  end
end
