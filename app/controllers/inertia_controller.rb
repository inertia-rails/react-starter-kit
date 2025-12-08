# frozen_string_literal: true

class InertiaController < ApplicationController
  include Alba::Inertia::Controller

  inertia_share { SharedPropsSerializer.new(self).to_inertia }
end
