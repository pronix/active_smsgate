# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'httparty'
require 'nokogiri'
require 'digest'
require "zlib"

require "active_smsgate/gateway"
Dir.glob(File.join('active_smsgate', "gateway", "*.rb")).each do |gw|
  require gw
end

module ActiveSmsgate
  VERSION = "0.0"
  class << self

    def log message
      puts "lid ---------------"
      # logger.info("[active_smsgate] #{message}") #if logging?
    end

    def logger #:nodoc:
      # # ActiveRecord::Base.logger
      # FILE = "sms_send.log"
      # $logger = Logger.new(FILE,3,5000000)
    end

    def logging? #:nodoc:
      true #options[:log]
    end

  end
end
