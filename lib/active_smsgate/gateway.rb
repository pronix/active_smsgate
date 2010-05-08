# -*- coding: utf-8 -*-
require 'httparty'
require 'nokogiri'
module ActiveSmsgate #:nodoc:
  module Gateway #:nodoc:
    class Gateway
      include HTTParty
      attr_accessor :login, :password, :use_ssl

      # Initialize a new gateway.
      def initialize(options = {})
        raise "Be sure to login and password" if options[:login].blank? || options[:password].blank?
        @login, @password = options[:login], options[:password]
        @use_ssl = options[:ssl] || false
      end

      # Использовать https или http
      def use_ssl?; @use_ssl end

    end
  end
end


# require File.join(File.dirname(__FILE__),"gateway",'amegainform')
# require File.join(File.dirname(__FILE__),"gateway",'mobak')

# =begin rdoc
# Шлюз возвращает result & closed или nil если ошибки
# return = { :result => 1, :closed => 2 }
# =end
# module Gateway
#   # ид шлюзов
#   GATEWAYS = { 1 => :amegainform , 2 => :mobak}

#   class << self
#     # Коды соотвествия результата
#     def code_result
#       {
#         :null => 0,
#         :queued => 1,
#         :wait => 2,
#         :accepted => 3,
#         :delivered => 4,
#         :notdelivered => 5,
#         :failed => 6
#       }
#     end

#     # Запрос подтверждения отправки смс
#     # с конкретного шлюза

#     def reply_sms(sms_data, gateway)
#       @options = {
#         :sms_id => sms_data[1],            # id sms
#         :sms_gw => sms_data[2],            # gateway
#         :login => gateway['login'],        # логин на шлюз
#         :password => gateway['password'],  # пароль на шлюз
#         :rgid => gateway["rgid"]           # ид шлюза
#       }

#       case GATEWAYS[gateway["rgid"].to_i]
#       when :amegainform
#         Amegainform.reply_sms(@options)
#       when :mobak
#         Mobak.reply_sms(@options)
#       end
#     end # end reply sms


#     # options - :phone, :sender, :message, :gateway, :user, :password, :rgid
#     def send_sms(*args)
#       @_options = args.last.is_a?(::Hash) ? args.pop : {}
#       @options = { }
#       @_options.each { |k,v| @options[k.to_sym] = v }

#       # HashWithIndifferentAccess
#       raise "Wrong parameters" unless [:phone, :sender,  :message,
#                                        :gateway, :user, :password, :rgid].all? {|w|
#                                         @options.keys.include? w }

#       case GATEWAYS[@options[:rgid].to_i]
#       when :amegainform
#         Amegainform.send_sms(@options)
#       when :mobak
#         Mobak.send_sms(@options)
#       end
#     # rescue
#     #   nil
#     end # end send_sms

#   def get_balance(*args)
#     @_options = args.last.is_a?(::Hash) ? args.pop : {}
#     @options = { }
#     @_options.each { |k,v| @options[k.to_sym] = v }
#     case GATEWAYS[@options[:rgid].to_i]
#     when :amegainform
#       Amegainform.balance(@options)
#     # when :mobak
#     #   Mobak.balance(@options)
#     else
#       nil
#     end
#   end # end get_balance
#   end
# end
