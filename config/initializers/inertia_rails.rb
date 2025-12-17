# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.encrypt_history = Rails.env.production?
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true

  config.parent_controller = "::InertiaController"
end
