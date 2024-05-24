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

