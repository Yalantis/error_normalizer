# frozen_string_literal: true

require_relative 'lib/error_normalizer/version'

Gem::Specification.new do |spec|
  spec.name          = 'error_normalizer'
  spec.version       = ErrorNormalizer::VERSION
  spec.authors       = ['Denis Kondratenko', 'Aleksandra Stolyar']
  spec.email         = ['di.kondratenko@gmail.com']

  spec.summary       = 'Normalize dry-validation and ActiveModel errors to the universal format'
  spec.homepage      = 'https://github.com/Yalantis/error_normalizer'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency 'dry-configurable', '~> 0.7.0'
  spec.add_development_dependency 'i18n', '~> 1'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'dry-validation', '~> 0.12.2'
  spec.add_development_dependency 'pry-byebug', '~> 3.6'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.59.2'
end
