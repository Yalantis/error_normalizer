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

    def initialize(input, namespace: nil, **config)
      @input = input
      @namespace = namespace
      @errors = []
      @config = config
    end

    def add_error(error, path: nil, **options)
      @errors <<
        case error
        when Error
          error
        when Symbol, String
          parse_error(error, path, options)
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

    def normalize_hash(input) # rubocop:disable AbcSize
      return add_error(input) if input.is_a?(Error)

      input.each do |key, value|
        if messages_ary?(value)
          options = prepare_error_options(key)
          value.each { |msg| add_error(msg, options) }
        elsif value.is_a?(Hash)
          ns = namespaced_path(key)
          Normalizer.new(value, namespace: ns).normalize.errors.each { |e| add_error(e) }
        else
          raise UnsupportedInputType
        end
      end
    end

    def messages_ary?(ary)
      return false unless ary.is_a? Array

      ary.all? { |v| v.is_a? String }
    end

    def parse_error(err_message, path, options)
      result = MessageParser.new(err_message).parse
      key, msg, payload = result.to_a

      Error.new(key, message: msg, path: namespaced_path(path), **payload, **options)
    end

    def namespaced_path(path)
      return if path.nil?
      return path.to_s if @namespace.nil?

      [@namespace, path].compact.join('.')
    end

    def prepare_error_options(key)
      type = 'params'
      payload = {}

      if @config[:infer_type_from_rule_name] && @config[:rule_matcher].match?(key)
        type = @config[:type_name]
      else
        payload = { path: key }
      end

      payload.merge!(type: type)
    end
  end
end
