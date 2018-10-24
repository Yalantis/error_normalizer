# frozen_string_literal: true

require 'dry-validation'

RSpec.describe 'dry-validation error format normalization' do
  subject(:result) { ErrorNormalizer.normalize(errors) }

  let(:schema) { Dry::Validation.Schema }
  let(:input) { Hash[] }
  let(:errors) { schema.call(input).errors }

  # @see https://dry-rb.org/gems/dry-validation/nested-data/
  context 'with "nested data" schema' do
    let(:schema) do
      Dry::Validation.Schema do
        required(:foo).schema do
          required(:bar).schema do
            required(:baz).filled
          end
        end
      end
    end

    let(:input) { Hash[foo: { bar: {} }] }

    it 'noramlizes errors' do
      expect(result).to match_array [
        {
          key: 'is_missing',
          message: 'is missing',
          payload: { path: 'foo.bar.baz' },
          type: 'params'
        }
      ]
    end

    # @see https://dry-rb.org/gems/dry-validation/array-as-input/
    context 'with "array as input" schema' do
      let(:schema) do
        Dry::Validation.Schema do
          required(:users).each do
            schema do
              required(:name).filled(:str?)
              required(:age).filled(:int?)
            end
          end
        end
      end

      let(:input) do
        { users: [{ name: 'Jane', age: 21 }, { name: 'Joe', age: nil }, { name: nil, age: 18 }] }
      end

      it 'normalizes errors' do
        expect(result).to match_array [
          {
            key: 'must_be_filled',
            message: 'must be filled',
            payload: { path: 'users.1.age' },
            type: 'params'
          }, {
            key: 'must_be_filled',
            message: 'must be filled',
            payload: { path: 'users.2.name' },
            type: 'params'
          }
        ]
      end
    end

    # @see https://dry-rb.org/gems/dry-validation/high-level-rules/
    context 'with "high level rules" in a schema' do
      let(:schema) do
        Dry::Validation.Schema do
          required(:login).filled(:bool?)
          required(:email).maybe(:str?)

          rule(email_presence: %i[login email]) do |login, email|
            login.true?.then(email.filled?)
          end
        end
      end

      let(:input) { Hash[login: true] }

      it 'normalizes errors' do
        expect(result).to match_array [
          {
            key: 'is_missing',
            message: 'is missing',
            payload: { path: 'email' },
            type: 'params'
          }
        ]
      end
    end

    # @see https://dry-rb.org/gems/dry-validation/custom-validation-blocks/
    context 'with "custom validation blocks" in a schema' do
      let(:schema) do
        Dry::Validation.Schema do
          configure do
            def self.messages
              super.merge(en: { errors: { email_required: 'provide email' } })
            end
          end

          required(:email).maybe(:str?)
          required(:newsletter).value(:bool?)

          validate(email_required: %i[newsletter email]) do |newsletter, email|
            if newsletter == true
              !email.nil?
            else
              true
            end
          end
        end
      end

      let(:input) { Hash[newsletter: true, email: nil] }

      # @note
      #   Would be cool to fix this. However it would be really hack-ish and hard.
      #   Clean solution to this problem would be type inference by the rule name (see spec below).
      #
      it 'normalizes errors' do
        expect(result).to match_array [{
          key: 'provide_email',
          message: 'provide email',
          payload: { path: 'email_required' }, # should be empty to not confuse ppl
          type: 'params' # should be "rule" or "custom" but definately not "params"
        }]
      end
    end

    # @see https://dry-rb.org/gems/dry-validation/custom-validation-blocks/
    context 'with "custom validation block" and type inference by rule name' do
      let(:schema) do
        Dry::Validation.Schema do
          configure do
            def self.messages
              super.merge(en: { errors: { email_required_rule: 'provide email' } })
            end
          end

          required(:email).maybe(:str?)
          required(:newsletter).value(:bool?)

          validate(email_required_rule: %i[newsletter email]) do |newsletter, email|
            if newsletter == true
              !email.nil?
            else
              true
            end
          end
        end
      end

      let(:input) { Hash[newsletter: true, email: nil] }

      it 'normalizes errors' do
        expect(result).to match_array [{
          key: 'provide_email',
          message: 'provide email',
          payload: {},
          type: 'rule'
        }]
      end
    end
  end
end
