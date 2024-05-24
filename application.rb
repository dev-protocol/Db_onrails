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
    config.action_view.preload_links_header = false

    # Rails 5.2
    config.action_dispatch.use_authenticated_cookie_encryption = false
    config.active_support.use_authenticated_message_encryption = false
    config.action_controller.default_protect_from_forgery = false
    config.action_view.form_with_generates_ids = false

    # Rails 5.1
    config.assets.unknown_asset_fallback = true

    # Rails 5.0
    config.action_controller.per_form_csrf_tokens = false
    config.action_controller.forgery_protection_origin_check = false
    ActiveSupport.to_time_preserves_timezone = false

    require_dependency Rails.root.join('lib/gitlab')
    require_dependency Rails.root.join('lib/gitlab/action_cable/config')
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/multi_store_wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/redis/queues')
    require_dependency Rails.root.join('lib/gitlab/redis/shared_state')
    require_dependency Rails.root.join('lib/gitlab/redis/trace_chunks')
    require_dependency Rails.root.join('lib/gitlab/redis/rate_limiting')
    require_dependency Rails.root.join('lib/gitlab/redis/sessions')
    require_dependency Rails.root.join('lib/gitlab/redis/repository_cache')
    require_dependency Rails.root.join('lib/gitlab/redis/db_load_balancing')
    require_dependency Rails.root.join('lib/gitlab/current_settings')
    require_dependency Rails.root.join('lib/gitlab/middleware/read_only')
    require_dependency Rails.root.join('lib/gitlab/middleware/compressed_json')
    require_dependency Rails.root.join('lib/gitlab/middleware/basic_health_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/same_site_cookies')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_ip_spoof_attack_error')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_malformed_strings')
    require_dependency Rails.root.join('lib/gitlab/middleware/path_traversal_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/rack_multipart_tempfile_factory')
    require_dependency Rails.root.join('lib/gitlab/runtime')
    require_dependency Rails.root.join('lib/gitlab/patch/database_config')
    require_dependency Rails.root.join('lib/gitlab/patch/redis_cache_store')
    require_dependency Rails.root.join('lib/gitlab/exceptions_app')

    config.exceptions_app = Gitlab::ExceptionsApp.new(Gitlab.jh? ? Rails.root.join('jh/public') : Rails.public_path)

    # This preload is required to:
    #
    # 1. Support providing sensitive DB configuration through an external script;
    # 2. Include Geo post-deployment migrations settings;
    config.class.prepend(::Gitlab::Patch::DatabaseConfig)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Sidekiq uses eager loading, but directories not in the standard Rails
    # directories must be added to the eager load paths:
    # https://github.com/mperham/sidekiq/wiki/FAQ#why-doesnt-sidekiq-autoload-my-rails-application-code
    # Also, there is no need to add `lib` to autoload_paths since autoloading is
    # configured to check for eager loaded paths:
    # https://github.com/rails/rails/blob/v4.2.6/railties/lib/rails/engine.rb#L687
    # This is a nice reference article on autoloading/eager loading:
    # http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload
    config.eager_load_paths.push(*%W[#{config.root}/lib
                                     #{config.root}/app/models/badges
                                     #{config.root}/app/models/hooks
                                     #{config.root}/app/models/members
                                     #{config.root}/app/graphql/resolvers/concerns
                                     #{config.root}/app/graphql/mutations/concerns
                                     #{config.root}/app/graphql/types/concerns])

    config.generators.templates.push("#{config.root}/generator_templates")

    foss_eager_load_paths = config.eager_load_paths.dup.freeze
    load_paths = lambda do |dir:|
      ext_paths = foss_eager_load_paths.each_with_object([]) do |path, memo|
        ext_path = config.root.join(dir, Pathname.new(path).relative_path_from(config.root))
        memo << ext_path.to_s
      end

      ext_paths << "#{config.root}/#{dir}/app/replicators"

      # Eager load should load CE first
      config.eager_load_paths.push(*ext_paths)
      config.helpers_paths.push "#{config.root}/#{dir}/app/helpers"

      # Other than Ruby modules we load extensions first
      config.paths['lib/tasks'].unshift "#{config.root}/#{dir}/lib/tasks"
      config.paths['app/views'].unshift "#{config.root}/#{dir}/app/views"
    end

    Gitlab.ee do
      load_paths.call(dir: 'ee')
    end

    Gitlab.jh do
      load_paths.call(dir: 'jh')
    end

    # Rake tasks ignore the eager loading settings, so we need to set the
    # autoload paths explicitly
    config.autoload_paths = config.eager_load_paths.dup

    # These are only used in Rake tasks so we don't need to add these to eager_load_paths
    config.autoload_paths.push("#{config.root}/lib/generators")
    Gitlab.ee { config.autoload_paths.push("#{config.root}/ee/lib/generators") }
    Gitlab.jh { config.autoload_paths.push("#{config.root}/jh/lib/generators") }

    # Add JH initializer into rails initializers path
    Gitlab.jh { config.paths["config/initializers"] << "#{config.root}/jh/config/initializers" }

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found).
    # We have to explicitly set default locale since 1.1.0 - see:
    # https://github.com/svenfuchs/i18n/pull/415
    config.i18n.fallbacks = [:en]

    # Translation for AR attrs is not working well for POROs like WikiPage
    config.gettext_i18n_rails.use_for_active_record_attributes = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    #
    # Parameters filtered:
    # - Any parameter ending with `token`
    # - Any parameter containing `password`
    # - Any parameter containing `secret`
    # - Any parameter ending with `key`
    # - Any parameter named `redirect`, filtered for security concerns of exposing sensitive information
    # - Two-factor tokens (:otp_attempt)
    # - Repo/Project Import URLs (:import_url)
    # - Build traces (:trace)
    # - Build variables (:variables)
    # - GitLab Pages SSL cert/key info (:certificate, :encrypted_key)
    # - Webhook URLs (:hook)
    # - Sentry DSN (:sentry_dsn)
    # - File content from Web Editor (:content)
    # - Jira shared secret (:sharedSecret)
    # - Titles, bodies, and descriptions for notes, issues, etc.
    #
    # NOTE: It is **IMPORTANT** to also update labkit's filter when
    #       adding parameters here to not introduce another security
    #       vulnerability:
    #       https://gitlab.com/gitlab-org/labkit/blob/master/mask/matchers.go
    config.filter_parameters += [
      /token$/,
      /password/,
      /secret/,
      /key$/,
      /^body$/,
      /^description$/,
      /^note$/,
      /^text$/,
      /^title$/,
      /^hook$/
