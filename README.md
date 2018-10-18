# Hola :call_me_hand:

This gem was born out of need to have a establish a single universal error format to be consumed by frontend (JS), Android and iOS clients.

## API error format

In our projects we have a convention, that in case of a failed request (422) backend shall return a JSON response which conforms to the following schema:

    {
      errors: [{
        key: 'has_already_been_taken',
        type: 'params',
        message: 'has already been taken',
        payload: {
          path: 'user.email'
        }
      }]
    }

Each error object **must have** 4 required fields: `key`, `type`, `message` and `payload`.

- `key` is a concise error code that will be used in a user-friendly translations
- `type` may be `params`, `custom` or something else
  - `params` means that some parameter that the backend received was wrong
  - `custom` covers everything else from the business validation composed from several parameters to something really special
- `message` is a "default" or "fallback" error message in plain English that may be used if client does not have translation for the error code
- `payload` contains other useful data that assists client error handling. For example, in case of `type: "params"` we can provide a _path_ to the invalid paramter.

## Usage

### dry-validation

GIVEN following [dry-validation](https://dry-rb.org/gems/dry-validation/) schema

    schema = Dry::Validation.Schema do
      required(:name).filled(size?: 3..15)
      required(:email).filled(format?: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
      optional(:credit_card).filled(:bool?)
      optional(:cash).filled(:bool?)

      rule(payment: [:credit_card, :cash]) do |card, cash|
        card.eql?(true) ^ cash.eql?(true)
      end
    end

AND following input

    errors = schema.call(name: 'DK', email: 'dk<@>dark.net').errors
    # {:name=>["length must be within 3 - 15"], :credit_card=>["must be filled"]}

THEN we can convert given errors to API error format

    ErrorNormalizer.normalize(errors)
    # [{
    #   :key=>"length_must_be_within",
    #   :message=>"length must be within 3 - 15",
    #   :payload=>{:path=>"name", :range=>["3", "15"]},
    #   :type=>"params"
    # }, {
    #   :key=>"is_in_invalid_format",
    #   :message=>"is in invalid format",
    #   :payload=>{:path=>"email"},
    #   :type=>"params"
    # }, {
    #   :key=>"must_be_equal_to",
    #   :message=>"must be equal to true",
    #   :payload=>{:path=>"payment", :value=>"true"},
    #   :type=>"params"
    # }]

For more information about supported errors and how they would be parsed please check the spec.

### ActiveModel::Validations

ActiveModel errors aren't fully supported. By that I mean errors will be converted to the single format, however you won't see really unique error `key` or `payload` with additional info.

GIVEN we have a model like this

    class TestUser
      include ActiveModel::Validations

      attr_reader :name, :email
      def initialize(name:, email:)
        @name = name
        @email = email
      end

      validates :name, presence: true, length: { in: 3..15 }
      validates :email, presence: true, format: { with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i }
    end

AND initialzied object with invalid data

    user = TestUser.new(name: 'DK', email: 'dk<@>dark.net').tap(&:validate)

THEN we can normalize object errors to API error format

    ErrorNormalizer.normalize(user.errors.to_hash)
    # [{
    #   :key=>"is_too_short_minimum_is_3_characters",
    #   :message=>"is too short (minimum is 3 characters)",
    #   :payload=>{:path=>"name"},
    #   :type=>"params"
    # }, {
    #   :key=>"is_invalid",
    #   :message=>"is invalid",
    #   :payload=>{:path=>"email"},
    #   :type=>"params"
    # }]

## TODO

- support dry-validation [nested data](https://dry-rb.org/gems/dry-validation/nested-data/)
- support dry-validation [array as input](https://dry-rb.org/gems/dry-validation/array-as-input/)
- parse ActiveModel error mesasges

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
