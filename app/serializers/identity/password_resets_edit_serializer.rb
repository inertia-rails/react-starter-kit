# frozen_string_literal: true

module Identity
  class PasswordResetsEditSerializer < ApplicationSerializer
    attributes :email, :sid
    typelize email: :string, sid: :string?
  end
end
