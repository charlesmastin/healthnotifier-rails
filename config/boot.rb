require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

### fix init failure: [2014.04.22 cathames]
###   /Users/macbookuser/u/run/rvm/rubies/ruby-1.9.3-p0/lib/ruby/1.9.1/psych/visitors/to_ruby.rb:217:in `merge!': can't convert nil into Hash (TypeError)
### help from: https://github.com/tenderlove/psych/issues/70
require 'yaml'
# YAML::ENGINE.yamler= 'syck'
