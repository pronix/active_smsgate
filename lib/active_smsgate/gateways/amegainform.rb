# -*- coding: utf-8 -*-

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
            :balance =>   (doc.at("//balance//AGT_BALANCE").inner_html rescue 0),
            :debt =>      (doc.at("//balance//PARENT_DEBT").inner_html rescue 0),
            :overdraft => (doc.at("//balance//OVERDRAFT").inner_html   rescue 0)
          }
        else
          @response
        #   raise
        end

        # error
      # rescue
        # nil

      end

      # Отправка сообщения

      # Параметры

      # * message - сообщение
      # * phones  - номера телефонов. Список через запятую. (Н-р: "+70010001212, 80009990000")
      # * sender  - имя отправителя, зарегистрированного в системе service.amegainform.ru.
      #            NULL - используется имя отправителя по умолчанию.


      # Nokogiri::XML::Builder.new do |xml|
      #   xml.output do
      #     xml.result(:sms_group_id => 996) do
      #       xml.sms(:id => '23234',:smstyoe => 'sendsms', :phone => '333', :sms_res_count => '1' ) {
      #         xml << "\<![CDATA[Привет]]\>"}
      #       xml.sms(:id => '999',:smstyoe => 'sendsms', :phone => '22', :sms_res_count => '11' ) {
      #         xml << "\<![CDATA[---------Привет---------]]\>"}
      #     end
      #   end
      # end


      # Возвращаемые данные
      # <output>
      # <result sms_group_id="996">
      # <sms id="99991" smstype="SENDSMS" phone="+79999999991" sms_res_count="1"><![CDATA[Привет]]></sms>
      # <sms id="99992" smstype="SENDVOICE" phone="+79999999992" sms_res_count="38"><![CDATA[%PAUSE=1000%%SYNTH=Vika%Привет друг%SAMPLE=#1525%%PAUSE=1000%%SYNTH=Vika%С днём рождения!]]></sms>
      # </result>
      # <output>

      def deliver(options = { :sender => nil})
        @options = {
          :action  => "post_sms",
          :message => options[:message],
          :target  => options[:phones],
          :sender  => options[:sender] }

        @response = self.class.post("#{uri}/sendsms", :query => @options.merge(auth_options))
        if @response.code == 200
          xml = Zlib::GzipReader.new( StringIO.new( @response ) ).read
          parse(xml)
          { :sms => @sms, :messages => @messages, :errors => @errors}
        else
          raise
        end
      rescue
        nil
      end



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
          parse(xml)
          { :sms => @sms, :messages => @messages, :errors => @errors}
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
        self.class.default_options[:base_uri].gsub!(/^https?:\/\//i, '')
        "http#{'s' if use_ssl?}://#{self.class.default_options[:base_uri]}"
      end


      # Разбираем ответ от сервиса amegainform
      def parse(xml)
        doc = Nokogiri::XML(xml)
        @sms, @messages, @errors = nil, nil, nil
        # Ответ от отправка смс
        @sms = doc.at("//output//result") && doc.at("//output//result").
          children.search("//sms").map {|x|
          _x ={}
          x.each { |v,l| _x[v.downcase.to_sym] = l }
          _x[:text] = x.inner_html
          _x
        }

        # Сообщения о доставках смс
        @messages = doc.at("//output//MESSAGES") && doc.at("//output//MESSAGES").
          children.search("//MESSAGE").map { |x|
          _x = { }
          x.each { |v,l| _x[v.downcase.to_sym] = l }
          x.children.each {|n| _x[n.name.downcase.to_sym] = n.inner_html unless n.blank? }
          _x
        }

        # Сообщения об ошибках
        @errors = doc.at("//output//errors") && doc.at("//output//errors").
          children.search("//error").map {|x| x.inner_html }

        { :sms => @sms, :messages => @messages, :errors => @errors}
      end
    end
  end
end
