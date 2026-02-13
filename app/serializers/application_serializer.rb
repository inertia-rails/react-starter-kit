# frozen_string_literal: true

class ApplicationSerializer
  include Alba::Resource

  helper Typelizer::DSL
  helper Alba::Inertia::Resource

  include Rails.application.routes.url_helpers
end
