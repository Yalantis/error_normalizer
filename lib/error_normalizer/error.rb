# frozen_string_literal: true

class ErrorNormalizer
  #
  # Struct which makes cosmetic normalization on calling
  # either {Error#to_hash} or {Error#to_json}.
  #
  # Translates message with path via i18n if
  # corresponding options is passed (see {Error#initialize}).
  #
  # Provides case equality check ({Error.===})
  # to support plain Hash structs.
  #
  # @example
  #   Error.new('not_plausible', message: "can't recognize your phone", path: 'user.phone')
  #   Error.new('not_authorized').to_hash
  #   #=> { key: 'not_authorized', message: 'not authorized', type: 'params', payload: {} }
  #
  #   # case equality works with hashes
  #   err = { key: 'err', message: 'err', type: 'custom', payload: {} }
  #   message =
  #     case err
  #     when Error
  #       'YEP'
  #     else
  #       'NOPE'
  #     end
  #   puts message #=> 'YEP'
  #
  class Error
    def initialize(error_key, message: nil, type: 'params', i18n_messages: nil, **payload)
      @key = error_key
      @message = message
      @type = type
      @payload = payload
      @i18n_messages =
        i18n_messages.nil? ? ErrorNormalizer.config.i18n_messages : i18n_messages
    end

    # Case equality check
    # @return [Boolean]
    def self.===(other)
      return true if other.is_a?(Error)
      return false unless other.is_a?(Hash)

      h = other.transform_keys(&:to_s)
      h.key?('key') && h.key?('message') && h.key?('payload') && h.key?('type')
    end

    # Translate message with path via i18n.
    # Delegates path translation to {SchemaPathTranslator}.
    # @return [String]
    def full_message
      return message unless @i18n_messages && @type == 'params'

      path = payload[:path]
      return if path.nil?

      translate_path(path)
    end

    # @return [Hash] error Hash representation
    def to_hash
      {
        key: @key,
        message: full_message,
        payload: payload,
        type: @type
      }
    end

    # @return [String] error JSON string representation
    def to_json
      to_hash.to_json
    end

    private

    def message
      @message || translate_message || humanize_key
    end

    def payload
      @payload.delete_if { |_k, v| v.nil? || v.empty? }
    end

    def translate_path(path)
      require 'error_normalizer/schema_path_translator' # do not load if not needed

      path_translation = SchemaPathTranslator.new(path).translate
      "#{path_translation} #{message}"
    end

    def translate_message
      return unless @i18n_messages

      require 'i18n' # do not load if not needed
      path = "errors.#{@key}"

      I18n.t(path) if I18n.exists?(path)
    end

    def humanize_key
      @key.tr('_', ' ')
    end
  end
end
