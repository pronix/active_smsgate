# -*- coding: utf-8 -*-
module ActiveSmsgate #:nodoc:
  module Gateway #:nodoc:

    class << self
      # Список поддерживаемых
      def support_gateways
        [{:class => 'amegainform',:desc => 'www.amegainform.ru' }]
      end
    end

    class Gateway
      include HTTParty
      attr_accessor :login, :password, :use_ssl

      # Initialize a new gateway.
      # ==== Параметры
      #
      # * <tt>:login</tt>         -- REQUIRED
      # * <tt>:password</tt>      -- REQUIRED
      # * <tt>:ssl</tt>           -- использовать https (OPTIONAL)
      # * <tt>:backup_server</tt> -- использовать адреса резервных серверов (OPTIONAL)
      def initialize(options = {})
        raise "Be sure to login and password" if options[:login].blank? || options[:password].blank?
        @login, @password = options[:login], options[:password]
        @use_ssl = options[:ssl] || false
        @use_of_backup_server = options[:backup_server] || false
      end

      # Использовать https или http
      def use_ssl?; @use_ssl end

      # Использовать резервные сервера
      def use_of_backup_server?; @use_of_backup_server  end

    end
  end
end
