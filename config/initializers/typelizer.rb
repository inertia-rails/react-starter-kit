# frozen_string_literal: true

Typelizer.configure do |config|
  config.routes.enabled = true
  config.routes.exclude = [/^\/rails/, /^\/up/]
end
