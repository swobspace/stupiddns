#!/usr/bin/env ruby

require 'rubydns'
require 'yaml'
require 'logger'

TTL = 60

CONFIG = YAML.load_file('config/application.yml') || {}
puts CONFIG.inspect
INTERFACES = CONFIG['interfaces'] || raise(ArgumentError, "Interfaces not configured")
ANSWER_IP  = CONFIG['answer_ip']  || raise(ArgumentError, "Answer ip not configured")
ANSWER_TXT = CONFIG['answer_txt'] || "What do you want for nothing?"
LOGLEVEL   = CONFIG['loglevel']   || Logger::INFO

def mylogger
  @mylogger ||= Logger.new('log/requests.log', 'weekly')
  @mylogger.level = LOGLEVEL
  @mylogger
end

def logme(transaction)
  type = "#{transaction.resource_class}".gsub(/\AResolv::DNS::Resource::/, "")

  mylogger.debug { 
    "options: #{transaction.options.inspect}\n" +
    "question: #{transaction.question.inspect}\n" +
    "resource_class: #{transaction.resource_class.inspect}\n"
  }
  mylogger.info { 
    "#{transaction.options[:peer].to_s} " +
    "question: #{transaction.question.to_s} " +
    "type: #{type}" 
  }
end

IN = Resolv::DNS::Resource::IN
Name = Resolv::DNS::Name

RubyDNS::run_server(:listen => INTERFACES) do
  match(/.*/, IN::A) do |transaction|
    logme(transaction)
    transaction.respond!(ANSWER_IP, ttl: TTL)
  end

  match(/.*/, IN::TXT) do |transaction|
    logme(transaction)
    transaction.respond!(ANSWER_TXT, ttl: TTL)
  end

  match(/.*/, IN::NS) do |transaction|
    logme(transaction)
    transaction.respond!(transaction.question, ttl: TTL)
  end

  match(/.*/, IN::SRV) do |transaction|
    logme(transaction)
    transaction.respond!(10, 0, 1024, transaction.question, ttl: TTL)
  end

  match(/.*/, IN::SOA) do |transaction|
    logme(transaction)
    transaction.respond!(
      Name.create("ns.mydomain.org."),    # Master Name
      Name.create("admin.mydomain.org."), # Responsible Name
      File.mtime(__FILE__).to_i,          # Serial Number
      1200,                               # Refresh Time
      60,                                 # Retry Time
      3600000,                            # Maximum TTL / Expiry Time
      172800,                             # Minimum TTL
      ttl: 60
    )
    transaction.append!(transaction.question, IN::NS, :section => :authority)
  end

  # -- cath all others with nxdomain
  otherwise do |transaction|
    logme(transaction)
    transaction.fail!(:NXDomain)
  end
end


