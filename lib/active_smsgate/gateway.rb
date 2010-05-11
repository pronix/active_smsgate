# -*- coding: utf-8 -*-
module ActiveSmsgate #:nodoc:
  module Gateway #:nodoc:
=begin rdoc
В каждом шлюзе нужно прописать три метода
  # Выполнение отправки смс завершено
  def complete;  end
  alias :complete? :complete

  # Смс досталена
  def success; end
  alias :success? :success

  # Смс не доставлена
  def failure; end
  alias :failure? :failure
=end
    class << self
      # Список поддерживаемых
      def support_gateways
        Dir["#{File.dirname(__FILE__)}/gateways/**/*.rb"].map { |gw|
          gateway = "active_smsgate/gateway/#{File.basename(gw, ".rb")}".classify.constantize
          { :class => File.basename(gw, ".rb"),  :alias => gateway::ALIAS,
            :short_desc => gateway::SHORT_DESC, :desc => gateway::DESC}    }
      end

      # получение шлюза по его имени
      def gateway(gw)
        "active_smsgate/gateway/#{gw.to_s}".classify.constantize
      end

    end

    class Gateway
      include HTTParty
      attr_accessor :login, :password, :use_ssl, :errors

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

      # Получение uri смс сервиса
      def uri
        self.class.default_options[:base_uri].gsub!(/^https?:\/\//i, '')
        "http#{'s' if use_ssl?}://#{self.class.default_options[:base_uri]}"
      end

      def valid?
        @errors.blank?
      end


    end
  end
end
