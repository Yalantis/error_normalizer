# frozen_string_literal: true

class ErrorNormalizer
  #
  # Parse error messages and extract payload metadata.
  #
  # ActiveModel ignored for now because we don't plan to use its validations.
  # In case message isn't recognized we set error to be a simple
  # normalized message (no spaces and special characters).
  #
  # Here are the links to AM::Errors and Dry::Validation list of error messages:
  #   - Dry: https://github.com/dry-rb/dry-validation/blob/8417e8/config/errors.yml
  #   - AM: https://github.com/svenfuchs/rails-i18n/blob/70b38b/rails/locale/en-US.yml#L111
  #
  class MessageParser
    VALUE_MATCHERS = [
      /\A(?<err>must not include) (?<val>.+)/,
      /\A(?<err>must be equal to) (?<val>.+)/,
      /\A(?<err>must not be equal to) (?<val>.+)/,
      /\A(?<err>must be greater than) (?<val>\d+)/,
      /\A(?<err>must be greater than or equal to) (?<val>\d+)/,
      /\A(?<err>must include) (?<val>.+)/,
      /\A(?<err>must be less than) (?<val>\d+)/,
      /\A(?<err>must be less than or equal to) (?<val>\d+)/,
      /\A(?<err>size cannot be greater than) (?<val>\d+)/,
      /\A(?<err>size cannot be less than) (?<val>\d+)/,
      /\A(?<err>size must be) (?<val>\d+)/,
      /\A(?<err>length must be) (?<val>\d+)/
    ].freeze

    LIST_MATCHERS = [
      /\A(?<err>must not be one of): (?<val>.+)/,
      /\A(?<err>must be one of): (?<val>.+)/,
      /\A(?<err>size must be within) (?<val>.+)/,
      /\A(?<err>length must be within) (?<val>.+)/
    ].freeze

    def initialize(message)
      @message = message
      @key = nil
      @payload = {}
    end

    def parse
      parse_value_message
      return to_a if @key

      parse_list_message
      return to_a if @key

      @key = to_key(@message)
      to_a
    end

    def to_a
      [@key, @message, @payload]
    end

    private

    def parse_value_message
      VALUE_MATCHERS.each do |matcher|
        data = matcher.match(@message)
        next if data.nil?

        @key = to_key(data[:err])
        @payload[:value] = data[:val]

        break
      end
    end

    def parse_list_message
      LIST_MATCHERS.each do |matcher|
        data = matcher.match(@message)
        next if data.nil?

        @key = to_key(data[:err])
        @payload.merge!(parse_list_payload(data[:val]))

        break
      end
    end

    def to_key(msg)
      msg.downcase.tr(' ', '_').gsub(/[^a-z0-9_]/, '')
    end

    def parse_list_payload(str)
      if str.include?(' - ')
        { range: str.split(' - ') }
      else
        { list: str.split(', ') }
      end
    end
  end
end
