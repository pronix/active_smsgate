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
      # sms_id - ид смс


      # Возвращаемые данные
      # -------------------------------------------------------------------
      # SMS_ID - ID сообщения
      # SMS_GROUP_ID - ID рассылки сообщений
      # SMSTYPE - тип сообщения
      # CREATED - дата и время создания сообщения
      # AUL_USERNAME - Имя пользователя создавшего сообщение
      # AUL_CLIENT_ADR - IP адрес пользователя создавшего сообщение
      # SMS_SENDER - Имя отправителя сообщения
      # SMS_TARGET - Телефон адресата
      # SMS_RES_COUNT - Кол-во единиц ресурсов на данное сообщение
      # SMS_TEXT - Текст сообщения
      # SMSSTC_CODE - Код статуса доставки сообщения
      # -- queued - сообщение в очереди отправки
      # -- wait -	передано оператору на отправку
      # -- accepted -	сообщение принято оператором, но статус доставки неизвестен
      # -- delivered -сообщение доставлено
      # -- not_delivered - сообщение не доставлено
      # -- failed - ошибка при работе по сообщению
      # SMS_STATUS - Текстовое описание статуса доставки сообщения
      # SMS_CLOSED - [0,1] 0 - сообщения находится в процессинге.
      #                    1 = работа по отправке сообщения завершена
      # SMS_SENT - [0,1] 0 - сообщение не отослано. 1 = сообщение отослано успешно
      # SMS_CALL_DURATION - Время,
      #              в течение которого было установлено соединение для отправки сообщения.
      # SMS_DTMF_DIGITS - Что пользователь нажимал в сеансе разговора (для SENDVOICE (в разработке))
      # SMS_CLOSE_TIME - Время завершения работы по сообщению.

      def reply(sms_id)
        @options = { :action => "status", :sendtype => "SENDSMS", :sms_id => sms_id }
        @response = self.class.post("#{uri}/sendsms", :query => @options.merge(auth_options))

        if @response.code == 200
          xml = Zlib::GzipReader.new( StringIO.new( @response ) ).read
          doc = Nokogiri::XML(xml)
          @attr = { }
          doc.at("//MESSAGES//MESSAGE").each {|x, t| attr[x.downcase.to_sym] = t}
          doc.at("//MESSAGES//MESSAGE").children.
            map { |t| attr[t.name.downcase.to_s] = t.inner_html unless t.blank? }.compact
          @attr
        else
          raise
        end
      rescue
        nil
      end


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
