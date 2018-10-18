# frozen_string_literal: true

require 'error_normalizer/version'
require 'error_normalizer/normalizer'

#
# Intended to normalize errors to the single format:
#
#     {
#       key: 'has_already_been_taken',
#       type: 'params',
#       message: 'has already been taken',
#       payload: {
#         path: 'user.email'
#       }
#     }
#
# We shall be able to automatically convert dry-validation output to this format
# and since we're using rails also automatically convert ActiveModel::Errors.
#
# Here are the links to AM::Errors and Dry::Validation list of errors:
#   - AM: https://github.com/svenfuchs/rails-i18n/blob/70b38b/rails/locale/en-US.yml#L111
#   - Dry: https://github.com/dry-rb/dry-validation/blob/8417e8/config/errors.yml
#
class ErrorNormalizer
  #
  # Normalize errors to flat array of structured errors.
  #
  # @param input [Hash]
  # @param opts [Hash] for list of supported options check ErrorNormalizer::Normalizer#new
  # @return [Array<Hash>]
  #
  def self.normalize(input, **opts)
    Normalizer.new(input, opts).normalize.to_a
  end
end
