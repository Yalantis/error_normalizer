# frozen_string_literal: true

require_relative 'error'
require_relative 'message_parser'

class ErrorNormalizer
  #
  # Responsible for converting input to the array of normalized errors.
  #
  # @example
  #   errors = { phone: ['not plausible'] }
  #   ErrorNormalizer::Normalizer.new(errors, namespace: 'customer').normalize
  #   # [{
  #   #   key: 'not_plausible',
  #   #   message: 'not plausible',
  #   #   payload: { path: 'customer.phone' },
  #   #   type: 'params'
  #   # }]
  #
  class Normalizer
    UnsupportedInputType = Class.new(StandardError)

    attr_reader :errors

    def initialize(input, namespace: nil)
      @input = input
      @namespace = namespace
      @errors = []
    end

    def add_error(error, path: nil, **options)
      @errors <<
        case error
        when Error
          error
        when Symbol, String
          err, msg, payload = parse_message(error)
          Error.new(err, message: msg, path: namespaced_path(path), **options, **payload)
        end
    end

    def normalize
      case @input
      when Hash
        normalize_hash(@input.dup)
      when ActiveModel::Errors
        normalize_hash(@input.to_hash)
      else
        raise "Don't know how to normalize errors"
      end

      self
    end

    def to_a
      @errors.map(&:to_hash)
    end

    private

    def normalize_hash(input)
      return add_error(input) if input.is_a?(Error)

      input.each do |key, value|
        if messages_ary?(value)
          value.each { |msg| add_error(msg, path: key) }
        elsif value.is_a?(Hash)
          Normalizer.new(value, namespace: key).normalize.errors.each { |e| add_error(e) }
        else
          raise UnsupportedInputType
        end
      end
    end

    def messages_ary?(ary)
      return false unless ary.is_a? Array

      ary.all? { |v| v.is_a? String }
    end

    def namespaced_path(path)
      return if path.nil? && @namespace.nil?

      [@namespace, path].compact.join('.')
    end

    def parse_message(msg)
      MessageParser.new(msg).parse
    end
  end
end
