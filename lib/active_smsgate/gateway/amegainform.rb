# -*- coding: utf-8 -*-
require "zlib"

module ActiveSmsgate #:nodoc:
  # «Амега Информ» – http://amegainform.ru/
  # это сервис  массовой рассылки, приема SMS и голосовых сообщений.

  module Gateway #:nodoc:
    class Amegainform < Gateway
      VERSION = '0.0'

      headers 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      base_uri 'service.amega-inform.ru'

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
      def balance; end

      # Отправка сообщения
      def deliver(options = { }); end

      # Получение данных и статусов сообщений
      def reply(options = { }); end

    end
  end
end
