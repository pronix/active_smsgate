# -*- coding: utf-8 -*-
require "zlib"

module ActiveSmsgate #:nodoc:
  # «Амега Информ» – http://amegainform.ru/
  # это сервис  массовой рассылки, приема SMS и голосовых сообщений.

  module Gateway #:nodoc:
    class Amegainform < Gateway
      VERSION = '0.0'

      headers 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      base_uri 'http://service.amega-inform.ru'

      # Адреса резервных серверов: service-r1.amegainform.ru и service-r2.amegainform.ru

      # Создание нового шлюза  AmegaInformGateway
      # Для работы со шлюзом необходимы логин и пароль
      #
      # ==== Параметры
      #
      # * <tt>:login</tt> -- REQUIRED
      # * <tt>:password</tt> -- REQUIRED
      def initialize(options = {})
        @options = options
        super
      end

      # Получение текущего баланса
      # BALANCE             [текущее состояние счёта]
      # OVERDRAFT           [максимальных уход в минус]
      # PARENT_DEBT         [задолженность]
      def balance
        @response = self.class.post("#{uri}/sendsms",
                                    :query => { :action => "balance"}.merge(auth_options))
        if @response.code == 200
          xml = Zlib::GzipReader.new( StringIO.new( @response ) ).read
          doc = Nokogiri::XML(xml)
          {
            :balance => doc.at("//balance//AGT_BALANCE").inner_html,
            :debt => doc.at("//balance//PARENT_DEBT").inner_html,
            :overdraft => doc.at("//balance//OVERDRAFT").inner_html
          }
        else
          raise
        end

        # error
      rescue
        nil
      end

      # Отправка сообщения
      def deliver(options = { }); end

      # Получение данных и статусов сообщений
      def reply(options = { }); end

      private
      # Возвращает параметры для авторизации
      def auth_options; { :user => @login, :pass => @password }  end

      # Получение uri смс сервиса
      def uri
        @uri ||= self.class.default_options[:base_uri].gsub!(/^https?:\/\//i, '')
        "http#{'s' if use_ssl?}://#{@uri}"
      end

    end
  end
end
