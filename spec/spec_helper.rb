# this is my favorite way to require ever
begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

begin
  require 'mocha'
rescue LoadError
  require 'rubygems'
  gem 'mocha'
  require 'mocha'
end


module Spec::Example::ExampleGroupMethods
  def currently(name, &block)
    it("*** CURRENTLY *** #{name}", &block)
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])
