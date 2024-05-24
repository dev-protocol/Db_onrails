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
    # To switch a setting to the new default value, we just need to delete the specific line here.

    # Rails 7.0
    config.action_controller.raise_on_open_redirects = false
    config.action_dispatch.return_only_request_media_type_on_content_type = true
    config.action_mailer.smtp_timeout = nil # New default is 5
    config.action_view.button_to_generates_button_tag = nil # New default is true
    config.active_record.automatic_scope_inversing = nil # New default is true
    config.active_record.verify_foreign_keys_for_fixtures = nil # New default is true
    config.active_record.partial_inserts = true # New default is false
    config.active_support.cache_format_version = nil # New default is 7.0
    config.active_support.disable_to_s_conversion = false # New default is true
    config.active_support.executor_around_test_case = nil # New default is true
    config.active_support.isolation_level = nil # New default is thread
    config.active_support.key_generator_hash_digest_class = nil # New default is OpenSSL::Digest::SHA256
    config.active_support.use_rfc4122_namespaced_uuids = nil # New default is true

    # Rails 6.1
    config.action_dispatch.cookies_same_site_protection = nil # New default is :lax
    ActiveSupport.utc_to_local_returns_utc_offset_times = false
