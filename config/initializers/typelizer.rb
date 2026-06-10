# frozen_string_literal: true

Typelizer.configure do |config|
  config.verbatim_module_syntax = true
  config.routes.enabled = true
  config.routes.output_dir = Rails.root.join("app/javascript/routes")
  config.routes.exclude = [ /^\/(up|rails)/ ]
end
