# frozen_string_literal: true
require_relative 'boot'

# Based on https://github.com/rails/rails/blob/v6.0.1/railties/lib/rails/all.rb
# Only load the railties we need instead of loading everything
require 'rails'

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'action_cable/engine'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'

require 'gitlab/utils/all'

Bundler.require(*Rails.groups)

module Gitlab
  class Application < Rails::Application
    config.load_defaults 7.0
    # This section contains configuration from Rails upgrades to override the new defaults so that we
    # keep existing behavior.
    #
    # For boolean values, the new default is the opposite of the value being set in this section.
    # For other types, the new default is noted in the comments. These are also documented in
    # https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    #
