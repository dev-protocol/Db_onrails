# frozen_string_literal: true

# Set default values for object_store settings
class ObjectStoreSettings
  SUPPORTED_TYPES = %w[artifacts external_diffs lfs uploads packages dependency_proxy terraform_state pages
    ci_secure_files].freeze
  ALLOWED_OBJECT_STORE_OVERRIDES = %w[bucket enabled proxy_download cdn].freeze

  # To ensure the one Workhorse credential matches the Rails config, we
  # enforce consolidated settings on those accelerated
  # endpoints. Technically dependency_proxy and terraform_state fall
  # into this category, but they will likely be handled by Workhorse in
  # the future.
  #
  # ci_secure_files doesn't support Workhorse yet
  # (https://gitlab.com/gitlab-org/gitlab/-/issues/461124), and it was
  # introduced first as a storage-specific setting. To avoid breaking
  # consolidated settings for other object types, exclude it here.
  WORKHORSE_ACCELERATED_TYPES = SUPPORTED_TYPES - %w[pages ci_secure_files]

  # pages and ci_secure_files may be enabled but use legacy disk storage
  # we don't need to raise an error in that case
  ALLOWED_INCOMPLETE_TYPES = %w[pages ci_secure_files].freeze

  attr_accessor :settings

  # Legacy parser
  def self.legacy_parse(object_store, object_store_type)
    object_store ||= GitlabSettings::Options.build({})
    object_store['enabled'] = false if object_store['enabled'].nil?
    object_store['remote_directory'], object_store['bucket_prefix'] = split_bucket_prefix(
      object_store['remote_directory']
    )

    object_store['direct_upload'] = true
