# frozen_string_literal: true

RSpec.describe ErrorNormalizer do
  describe '.normalize' do
    subject(:result) { described_class.normalize(input, options) }

    let(:options) { Hash[] }

    context 'with "namespace" option' do
      let(:input) { Hash[email: ['invalid email']] }
      let(:options) { Hash[namespace: 'user'] }

      it 'returns namespaced path' do
        is_expected.to eq [{
          key: 'invalid_email',
          message: 'invalid email',
          payload: { path: 'user.email' },
          type: 'params'
        }]
      end
    end

    context 'with "exclusion list" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must not be one of: a, b, c' }

      it 'returns list in payload' do
        is_expected.to eq [{
          key: 'must_not_be_one_of',
          message: 'must not be one of: a, b, c',
          payload: {
            list: %w[a b c],
            path: 'param'
          },
          type: 'params'
        }]
      end
    end

    context 'with "exclusion range" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must not be one of: a - z' }

      it 'returns range in payload' do
        is_expected.to eq [{
          key: 'must_not_be_one_of',
          message: 'must not be one of: a - z',
          payload: {
            range: %w[a z],
            path: 'param'
          },
          type: 'params'
        }]
      end
    end

    context 'with "equality" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must be equal to DK' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_be_equal_to',
          message: message,
          payload: {
            path: 'param',
            value: 'DK'
          },
          type: 'params'
        }]
      end
    end

    context 'with "not equal" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must not be equal to DK' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_not_be_equal_to',
          message: message,
          payload: {
            path: 'param',
            value: 'DK'
          },
          type: 'params'
        }]
      end
    end

    context 'with "greater than" error message' do
      let(:input) { Hash[age: [message]] }
      let(:message) { 'must be greater than 17' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_be_greater_than',
          message: message,
          payload: {
            path: 'age',
            value: '17'
          },
          type: 'params'
        }]
      end
    end

    context 'with "greater than or equal to" error message' do
      let(:input) { Hash[age: [message]] }
      let(:message) { 'must be greater than or equal to 18' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_be_greater_than_or_equal_to',
          message: message,
          payload: {
            path: 'age',
            value: '18'
          },
          type: 'params'
        }]
      end
    end

    # https://github.com/dry-rb/dry-validation/blob/8417e8/config/errors.yml#L38
    context 'with "inclusion list" error message' do
      let(:input) { Hash[color: ['must be one of: red, green, blue']] }

      it 'returns list in payload' do
        is_expected.to eq [{
          key: 'must_be_one_of',
          message: 'must be one of: red, green, blue',
          payload: {
            list: %w[red green blue],
            path: 'color'
          },
          type: 'params'
        }]
      end
    end

    # https://github.com/dry-rb/dry-validation/blob/8417e8/config/errors.yml#L39
    context 'with "inclusion range" error message' do
      let(:input) { Hash[age: ['must be one of: 18 - 24']] }

      it 'returns range in payload' do
        is_expected.to eq [{
          key: 'must_be_one_of',
          message: 'must be one of: 18 - 24',
          payload: {
            path: 'age',
            range: %w[18 24]
          },
          type: 'params'
        }]
      end
    end

    context 'with "less than" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must be less than 100' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_be_less_than',
          message: message,
          payload: {
            path: 'param',
            value: '100'
          },
          type: 'params'
        }]
      end
    end

    context 'with "less than or equal to" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'must be less than or equal to 100' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'must_be_less_than_or_equal_to',
          message: message,
          payload: {
            path: 'param',
            value: '100'
          },
          type: 'params'
        }]
      end
    end

    context 'with "max size" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'size cannot be greater than 100' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'size_cannot_be_greater_than',
          message: message,
          payload: {
            path: 'param',
            value: '100'
          },
          type: 'params'
        }]
      end
    end

    context 'with "min size" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'size cannot be less than 100' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'size_cannot_be_less_than',
          message: message,
          payload: {
            path: 'param',
            value: '100'
          },
          type: 'params'
        }]
      end
    end

    context 'with "size" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'size must be 2' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'size_must_be',
          message: message,
          payload: {
            path: 'param',
            value: '2'
          },
          type: 'params'
        }]
      end
    end

    context 'with "size range" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'size must be within 2 - 4' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'size_must_be_within',
          message: message,
          payload: {
            path: 'param',
            range: %w[2 4]
          },
          type: 'params'
        }]
      end
    end

    context 'with "length" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'length must be 2' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'length_must_be',
          message: message,
          payload: {
            path: 'param',
            value: '2'
          },
          type: 'params'
        }]
      end
    end

    context 'with "length range" error message' do
      let(:input) { Hash[param: [message]] }
      let(:message) { 'length must be within 2 - 4' }

      it 'returns value in payload' do
        is_expected.to eq [{
          key: 'length_must_be_within',
          message: message,
          payload: {
            path: 'param',
            range: %w[2 4]
          },
          type: 'params'
        }]
      end
    end

    context 'with Error object as input' do
      let(:input) { ErrorNormalizer::Error.new(:not_registered, message: 'go home') }

      it 'returns normalized error' do
        is_expected.to eq [{
          key: :not_registered,
          message: 'go home',
          payload: {},
          type: 'params'
        }]
      end
    end

    context 'with hash being case-equal to Error object' do
      let(:input) do
        Hash[key: :not_registered, message: 'no no no', payload: {}, type: 'custom']
      end

      it 'returns identical error' do
        is_expected.to eq [{
          key: :not_registered,
          message: 'no no no',
          payload: {},
          type: 'custom'
        }]
      end
    end

    context 'with case-sensitive path translation' do
      let(:input) { Hash[some_important_license_number: ['has already been taken']] }
      before do
        ErrorNormalizer.config.i18n_messages = true

        I18n.backend.store_translations(
          :en,
          Hash[
            schemas: {
              some_important_license_number: {
                '@': 'some important LISENCE number',
              }
            }
          ]
        )
      end

      it 'returns error saving uppercase' do
        is_expected.to eq [{
          key: 'has_already_been_taken',
          message: 'Some important LISENCE number has already been taken',
          payload: {
            path: 'some_important_license_number'
          },
          type: 'params'
        }]
      end
    end
  end
end
