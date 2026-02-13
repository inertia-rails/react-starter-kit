# frozen_string_literal: true

class SharedPropsSerializer < ApplicationSerializer
  one :auth, source: proc { Current }
end
