#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'optparse'

options = {
  user_home: ENV['HOME']
}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: parse_json.rb [OPTIONS]"
  opt.separator  ""

  opt.on("--json-string JSONSTRING", "json string") do |value|
    options[:json_string] = value
  end

  opt.on("--prop PROP", "json property") do |value|
    options[:prop] = value
  end
  
end

opt_parser.parse!

unless options[:json_string] and options[:prop].length > 0
  #puts opt_parser
  exit 1
end

parsed = JSON.parse(options[:json_string])

val = parsed["#{options[:prop]}"]

puts "#{val}"