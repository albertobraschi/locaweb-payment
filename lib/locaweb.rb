require "rubygems"
require "builder"
require "soap/wsdlDriver"
require "ostruct"
require "hpricot"

%w(
  base
  payment
  result
  return
).each {|f| require File.dirname(__FILE__) + "/locaweb/#{f}" }