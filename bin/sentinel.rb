#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'optparse'

options = {
  verbose: false,
  environment: 'development',
  config_path: 'config/sentinel.yml'
}

OptionParser.new do |opts|
  opts.banner = "Usage: #$0 [-c <config>] [-e <env>]"

  opts.separator ""
  opts.separator "Specific options:"

  opts.on '-v', '--[no-]verbose', 'Enable verbose logging' do |verbose|
    options[:verbose] = verbose
  end

  opts.on '-c', '--config=PATH', 'Set the configuration file' do |config_path|
    options[:config_path] = config_path
  end

  opts.on '-eENV', '--environment=ENV', 'Environment to run in' do |environment|
    options[:environment] = environment
  end

  opts.on_tail '-h', '--help', 'Show this message' do
    puts opts
    exit
  end
end.parse!

config_path = File.expand_path options[:config_path]

unless File.readable? config_path
  fail "Configuration file `#{config_path}' is not readable!"
  exit 1
end

config = YAML.load_file config_path


require_relative '../lib/dr/sentinel'

# Set up a database connection
database_config = config.fetch 'db', {}
database_url = database_config.fetch 'url', DR::Sentinel::DEFAULT_DATABASE_URL

DR::Sentinel::Database = Sequel.connect database_url
DR::Sentinel.load_models!

@sentinel = DR::Sentinel::Server.new config_path, config
