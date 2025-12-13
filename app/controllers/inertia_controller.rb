# frozen_string_literal: true

class InertiaController < ApplicationController
  include Alba::Inertia::Controller

  inertia_share { SharedPropsSerializer.new(self).to_inertia }

  private

  def inertia_errors(model, full_messages: true)
    {
      errors: model.errors.to_hash(full_messages).transform_values(&:to_sentence)
    }
  end
end
