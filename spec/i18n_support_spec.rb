# frozen_string_literal: true

require 'spec_helper'
require 'i18n'
require 'error_normalizer/message_parser'

class RussianMessageParser < ErrorNormalizer::MessageParser
  locale :ru

  value_matcher :must_be_filled, /\A(?<err>должно быть заполненно)/u
  list_matcher :must_be_one_of, /\A(?<err>должно быть одним из): (?<val>.+)/u
  list_matcher :must_not_be_one_of, /\A(?<err>не должно быть одним из): (?<val>.+)/u
end

RSpec.describe 'I18n support features' do
  before(:all) { ErrorNormalizer.config.i18n_messages = true }
  after(:all) { ErrorNormalizer.config.i18n_messages = false }

  context 'when I18n has proper translations' do
    subject(:errors) { ErrorNormalizer.normalize(input) }

    before do
      ErrorNormalizer.config.message_parsers << RussianMessageParser

      I18n.backend.store_translations(
        :ru,
        Hash[
          schemas: {
            user: {
              '@': 'Юзер',
              name: 'Имя',
              account: {
                '@': 'Аккаунт',
                status: 'Статус'
              }
            }
          },
          role: {
            '@': 'Роль',
            name: 'Название'
          }
        ]
      )

      I18n.available_locales = %i[en ru]
      I18n.locale = :ru
    end

    after { I18n.locale = :en }

    let(:input) do
      Hash[
        user: {
          name: ['должно быть одним из: Виталик, Олежка'],
          account: {
            status: ['не должно быть одним из: ок, неок']
          }
        },
        role: {
          name: ['должно быть заполненно']
        }
      ]
    end

    it 'builds i18n "full" error messages' do
      is_expected.to match_array [{
        key: 'must_be_one_of',
        message: 'Юзер имя должно быть одним из: Виталик, Олежка',
        payload: {
          path: 'user.name',
          list: %w[Виталик Олежка]
        },
        type: 'params'
      }, {
        key: 'must_not_be_one_of',
        message: 'Юзер аккаунт статус не должно быть одним из: ок, неок',
        payload: {
          path: 'user.account.status',
          list: %w[ок неок]
        },
        type: 'params'
      }, {
        key: 'must_be_filled',
        message: 'Роль название должно быть заполненно',
        payload: {
          path: 'role.name'
        },
        type: 'params'
      }]
    end
  end

  context 'when error message is empty but we have translation for the error key' do
    subject { ErrorNormalizer::Error.new('no_way', type: 'custom').to_hash }

    before do
      I18n.backend.store_translations(
        :en,
        Hash[errors: { no_way: "really can't imagine how that could be true" }]
      )
    end

    it 'uses key translation as a message' do
      is_expected.to eq(
        key: 'no_way',
        message: "really can't imagine how that could be true",
        payload: {},
        type: 'custom'
      )
    end
  end
end
