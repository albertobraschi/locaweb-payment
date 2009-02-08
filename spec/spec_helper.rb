require "rubygems"
require "spec"
require File.dirname(__FILE__) + "/../init"
require "ruby-debug"
require "test_notifier/rspec"
require "hpricot"

RAILS_ENV = "test"
require File.dirname(__FILE__) + "/../../../../config/environment"

alias :doing :lambda