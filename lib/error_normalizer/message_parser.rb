# frozen_string_literal: true

class ErrorNormalizer
  #
  # Base implementation of the error message parser.
  # Message parsers attempt to extract key, message and payload from the given message.
  # Instances of {MessageParser} can't parse errors on its own because it does not define
  # any error matchers but it defines all necessary parse logic
  # since it doesn't depend on the locale.
  #
  # You can easily define your own parser by inheriting from {MessageParser}:
  #
  #   class RussianMessageParser < ErrorNormalizer::MessageParser
  #     locale :ru
  #
  #     value_matcher :must_be_equal_to, /(?<err>должен быть равным) (?<val>.+)/u
  #     list_matcher :must_be_on_of, /\A(?<err>должен быть одним из): (?<val>.+)/u
  #   end
  #
  # ActiveModel ignored for now because we don't plan to use its validations.
  # In case message isn't recognized we set error to be a simple
  # normalized message (no spaces and special characters).
  #
  # Here are the links to ActiveModel::Errors and Dry::Validation list of error messages:
  # - {https://github.com/dry-rb/dry-validation/blob/8417e8/config/errors.yml dry-validation}
  # - {https://github.com/svenfuchs/rails-i18n/blob/70b38b/rails/locale/en-US.yml#L111 ActiveModel::Errors}
  #
  class MessageParser
    AlreadyDefinedError = Class.new(StandardError)

    class << self
      # Get or set parser locale
      # @return [Symbol]
      def locale(i18n_locale = nil)
        return @locale if i18n_locale.nil?

        @locale = i18n_locale.intern
      end

      # Define message value matcher with a corresponding error key.
      # Value matchers add a "value" property to the error payload.
      # @param key [Symbol] set the error key for a given matcher
      # @param matcher [Regexp] match and extract error and payload via regexp named groups
      # @return [void]
      def value_matcher(key, matcher)
        raise ArgumentError, 'matcher should be a Regexp' unless matcher.is_a?(Regexp)

        key = key.to_s
        @value_matchers ||= {}

        raise AlreadyDefinedError if @value_matchers.key?(key)

        @value_matchers[key] = matcher
      end

      # Define message list matcher with a corresponding error key.
      # List matchers add a "list" or "range" property to the error payload.
      # @param key [Symbol] set the error key for a given matcher
      # @param matcher [Regexp] match and extract error and payload via regexp named groups
      # @return [void]
      def list_matcher(key, matcher)
        raise ArgumentError, 'matcher should be a Regexp' unless matcher.is_a?(Regexp)

        key = key.to_s
        @list_matchers ||= {}

        raise AlreadyDefinedError if @list_matchers.key?(key)

        @list_matchers[key] = matcher
      end

      # @return [Hash] value matchers
      attr_reader :value_matchers

      # @return [Hash] list matchers
      attr_reader :list_matchers
    end

    def initialize(message)
      @locale = self.class.locale
      @message = message
      @key = nil
      @payload = {}
    end

    # @return [String] parser locale
    attr_reader :locale

    # Parse error message
    # @return (see #to_a)
    def parse
      parse_value_message
      return to_a if @key

      parse_list_message
      return to_a if @key

      @key = normalize_message(@message)
      to_a
    end

    # @return [Array] a tuple of parsed [key, message, payload]
    def to_a
      [@key, @message, @payload]
    end

    private

    def parse_value_message
      self.class.value_matchers.each do |(key, matcher)|
        data = matcher.match(@message)
        next if data.nil?

        @key = key
        @payload[:value] = data[:val] if data.names.include?('val')

        break
      end
    end

    def parse_list_message
      self.class.list_matchers.each do |(key, matcher)|
        data = matcher.match(@message)
        next if data.nil?

        @key = key
        @payload.merge!(parse_list_payload(data[:val])) if data.names.include?('val')

        break
      end
    end

    # TODO: fine tune for UTF-8 messages
    def normalize_message(msg)
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
