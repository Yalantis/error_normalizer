# frozen_string_literal: true

class ErrorNormalizer
  #
  # Error struct which makes cosmetic normalization
  # upon calling either {Error#to_hash} or {Error#to_json}.
  # Provides case equality check {Error.===} to support plain Hash structs.
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

    # Case equality check
    # @return [Boolean]
    def self.===(other)
      return true if other.is_a?(Error)
      return false unless other.is_a?(Hash)

      h = other.transform_keys(&:to_s)
      h.key?('key') && h.key?('message') && h.key?('payload') && h.key?('type')
    end

    # @return [Hash] error Hash representation
    def to_hash
      {
        key: @key,
        message: message,
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
      @message || @key.tr('_', ' ')
    end

    def payload
      @payload.delete_if { |_k, v| v.nil? || v.empty? }
    end
  end
end
