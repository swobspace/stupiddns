#!/usr/bin/env ruby

require 'rubydns'
require 'yaml'

CONFIG = YAML.load_file('config/application.yml') || {}
puts CONFIG.inspect
INTERFACES = CONFIG['interfaces'] || raise(ArgumentError, "Interfaces not configured")
ANSWER_IP  = CONFIG['answer_ip']  || raise(ArgumentError, "Answer ip not configured")

IN = Resolv::DNS::Resource::IN

RubyDNS::run_server(:listen => INTERFACES) do
    match(/.*/, IN::A) do |transaction|
        transaction.respond!(ANSWER_IP)
    end

    # Default DNS handler
    otherwise do |transaction|
        transaction.passthrough!(UPSTREAM)
    end
end


