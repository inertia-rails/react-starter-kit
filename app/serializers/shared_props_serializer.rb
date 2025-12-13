# frozen_string_literal: true

class SharedPropsSerializer < ApplicationSerializer
  typelize "Flash"
  attribute :flash do |object, _|
    object.flash.to_hash
  end

  one :auth, source: proc { Current }
end
