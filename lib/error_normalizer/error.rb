# frozen_string_literal: true

class ErrorNormalizer
  # Error struct which makes cosmetic normalization
  # upon calling either #to_hash and #to_json.
  # Supports case equality check (#===) for hash structs.
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
    def initialize(error_key, message: nil, type: 'params', **payload)
      @key = error_key
      @message = message
      @type = type
      @payload = payload
    end

    def self.===(other)
      return true if other.is_a?(Error)
      return false unless other.is_a?(Hash)

      h = other.transform_keys(&:to_s)
      h.key?('key') & h.key?('message') && h.key?('payload') && h.key?('type')
    end

    def to_hash
      {
        key: @key,
        message: message,
        payload: payload,
        type: @type
      }
    end

    def to_json
      to_hash.to_json
    end

    private

    def message
      @message || @key.tr('_', ' ')
    end

    def payload
      @payload.delete_if { |_k, v| v.nil? || v.empty? }
    end
  end
end
