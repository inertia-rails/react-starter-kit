# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = RailsVite.digest
  config.encrypt_history = Rails.env.production?
  config.use_script_element_for_initial_page = true
  config.use_data_inertia_head_attribute = true
  config.always_include_errors_hash = true
  config.parent_controller = "::InertiaController"

  # Flip to true (and rebuild with --build-arg SSR_ENABLED=true) to enable SSR.
  config.ssr_enabled = true
end
