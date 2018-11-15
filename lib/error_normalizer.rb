# frozen_string_literal: true

require 'dry-configurable'
require 'error_normalizer/version'
require 'error_normalizer/normalizer'
require 'error_normalizer/message_parser/english'

#
# This class provides high-level API to normalize errors to the single format:
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
class ErrorNormalizer
  extend Dry::Configurable

  setting :infer_type_from_rule_name, true
  setting :rule_matcher, /_rule\z/
  setting :type_name, 'rule'
  setting :i18n_messages, false
  setting :message_parsers, [ErrorNormalizer::MessageParser::English]

  #
  # Normalize errors to flat array of structured errors.
  #
  # @param input [Hash]
  # @param opts [Hash] for list of supported options check ErrorNormalizer::Normalizer#new
  # @return [Array<Hash>]
  #
  def self.normalize(input, **opts)
    defaults = config.to_hash
    Normalizer.new(input, defaults.merge(opts)).normalize.to_a
  end
end
