require 'coveralls'
require 'simplecov'


SimpleCov.formatters = [
  Coveralls::SimpleCov::Formatter,
  SimpleCov::Formatter::HTMLFormatter,
]

SimpleCov.add_filter '/tests/'
SimpleCov.add_filter '/misc/'
