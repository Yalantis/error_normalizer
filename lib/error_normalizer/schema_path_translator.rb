# frozen_string_literal: true

class ErrorNormalizer
  #
  # Find I18n locale for the given path.
  #
  class SchemaPathTranslator
    def initialize(path)
      @path = path
      @namespace = 'schemas' # TODO: make it configurable
    end

    # Take the path and try to translate each part of it.
    # Given the path: "user.account.status" lookup path (and translation) will looks like:
    #
    #   schemas.user.@
    #   schemas.user
    #   user.@
    #   user
    #   +
    #   schemas.user.account.@
    #   schemas.user.account
    #   schemas.account.@
    #   schemas.account
    #   account.@
    #   account
    #   +
    #   schemas.user.account.status.@
    #   schemas.user.account.status
    #   schemas.status.@
    #   schemas.status
    #   status.@
    #   status
    #
    # @return [String] translated path
    #
    def translate
      tokens = @path.split('.')

      translated_tokens = []
      tokens.each.with_index do |token, i|
        translated_tokens << translate_token(token, i, tokens)
      end

      translated_tokens.join(' ').capitalize
    end

    private

    def translate_token(token, token_idx, all_tokens)
      translation = nil
      full_path = all_tokens[0..token_idx].join('.')

      lookup = build_lookup(token, full_path)
      lookup.each { |path| break translation = I18n.t(path) if I18n.exists?(path) }

      translation || token
    end

    def build_lookup(token, full_path)
      Set.new.tap do |lookup|
        lookup << "#{@namespace}.#{full_path}.@"
        lookup << "#{@namespace}.#{full_path}"
        lookup << "#{@namespace}.#{token}.@"
        lookup << "#{@namespace}.#{token}"
        lookup << "#{full_path}.@"
        lookup << full_path
        lookup << "#{token}.@"
        lookup << token
      end
    end
  end
end
