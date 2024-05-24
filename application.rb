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

