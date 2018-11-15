# frozen_string_literal: true

require 'error_normalizer/message_parser'

class ErrorNormalizer
  class MessageParser
    #
    # Parser tailored for dry-validation default error messages.
    #
    class English < MessageParser
      locale :en

      value_matcher :must_not_include, /\A(?<err>must not include) (?<val>.+)/
      value_matcher :must_be_equal_to, /\A(?<err>must be equal to) (?<val>.+)/
      value_matcher :must_not_be_equal_to, /\A(?<err>must not be equal to) (?<val>.+)/
      value_matcher :must_be_greater_than, /\A(?<err>must be greater than) (?<val>\d+)/
      value_matcher :must_be_greater_than_or_equal_to, /\A(?<err>must be greater than or equal to) (?<val>\d+)/
      value_matcher :must_include, /\A(?<err>must include) (?<val>.+)/
      value_matcher :must_be_less_than, /\A(?<err>must be less than) (?<val>\d+)/
      value_matcher :must_be_less_than_or_equal_to, /\A(?<err>must be less than or equal to) (?<val>\d+)/
      value_matcher :size_cannot_be_greater_than, /\A(?<err>size cannot be greater than) (?<val>\d+)/
      value_matcher :size_cannot_be_less_than, /\A(?<err>size cannot be less than) (?<val>\d+)/
      value_matcher :size_must_be, /\A(?<err>size must be) (?<val>\d+)/
      value_matcher :length_must_be, /\A(?<err>length must be) (?<val>\d+)/

      list_matcher :must_not_be_one_of, /\A(?<err>must not be one of): (?<val>.+)/
      list_matcher :must_be_one_of, /\A(?<err>must be one of): (?<val>.+)/
      list_matcher :size_must_be_within, /\A(?<err>size must be within) (?<val>.+)/
      list_matcher :length_must_be_within, /\A(?<err>length must be within) (?<val>.+)/
    end
  end
end
