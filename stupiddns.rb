#!/usr/bin/env ruby

require 'rubydns'
require 'yaml'
require 'logger'

logger = Logger.new('log/requests.log', 'weekly')

CONFIG = YAML.load_file('config/application.yml') || {}
puts CONFIG.inspect
INTERFACES = CONFIG['interfaces'] || raise(ArgumentError, "Interfaces not configured")
ANSWER_IP  = CONFIG['answer_ip']  || raise(ArgumentError, "Answer ip not configured")

IN = Resolv::DNS::Resource::IN

RubyDNS::run_server(:listen => INTERFACES) do
    match(/.*/, IN::A) do |transaction|
        logger.info { "#{transaction.options[:peer].to_s} question: #{transaction.question.to_s}" }
        transaction.respond!(ANSWER_IP)
    end

    # Default DNS handler
    otherwise do |transaction|
        transaction.passthrough!(UPSTREAM)
    end
end


