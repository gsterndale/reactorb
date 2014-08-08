require 'rspec'
require 'rspec/its'
require 'timecop'
require File.expand_path("../../lib/reactorb", __FILE__)

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
