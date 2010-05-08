# -*- coding: utf-8 -*-
require 'digest'

module ActiveSmsgate #:nodoc:
  # «Мобильный Актив» – http://mobak.ru/

  module Gateway #:nodoc:
    class Mobak < Gateway
      VERSION = '0.0'

      headers 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      base_uri 'partner.mobak.ru'

      # Создание нового шлюза  MobakGateway
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
