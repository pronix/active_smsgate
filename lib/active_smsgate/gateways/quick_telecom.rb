# -*- coding: utf-8 -*-
module ActiveSmsgate #:nodoc:
  module Gateway #:nodoc:

=begin rdoc
  "Quick Telecom" - http://www.qtelecom.ru/
   это сервис  массовой рассылки, приема SMS и голосовых сообщений.

   Примеры возвращаемых сообщений:
   Пример 1

   <output>
     <result>
     <sms id="99991" smstype="SENDSMS"  phone="+79999999991" sms_res_count="1"><![CDATA[Привет]]></sms>
     <sms id="99992"  smstype="SENDSMS"  phone="+79999999992" sms_res_count="1"><![CDATA[Привет]]></sms>
     </result>
     <errors>
     <error>Неправильный номер телефона: +7999999999999</error>
     </errors>
   </output>

  пример 2

  <output>
     <MESSAGES>
     <MESSAGE SMS_ID="6666" SMSTYPE="SENDSMS">
     <CREATED>24.12.07 15:57:45</CREATED> 
     <AUL_USERNAME>userX.Y</AUL_USERNAME> 
     <AUL_CLIENT_ADR>127.0.0.1</AUL_CLIENT_ADR> 
     <SMS_SENDER>SenderName</SMS_SENDER> 
     <SMS_TARGET>89999991111</SMS_TARGET> 
     <SMS_RES_COUNT>1</SMS_RES_COUNT> 
       <SMS_TEXT>
       <![CDATA[ Привет ]]> 
     </SMS_TEXT>
     <SMSSTC_CODE>wait</SMSSTC_CODE> 
     <SMS_STATUS>Сообщение в процессе доставки</SMS_STATUS> 
     <SMS_CLOSED>0</SMS_CLOSED> 
     <SMS_SENT>0</SMS_SENT> 
     </MESSAGE>
     </MESSAGES>
   </output>

  пример 3

  <output>
     <BALANCE>
     <AGT_BALANCE>1000</AGT_BALANCE>    [текущее состояние счёта]
     <OVERDRAFT>100</OVERDRAFT>         [максимальных уход в минус]
     </BALANCE>
  </output>

  Данные по сообщению:

      SMS_ID - ID сообщения
      SMS_GROUP_ID - ID рассылки сообщений
      SMSTYPE - тип сообщения
      CREATED - дата и время создания сообщения
      AUL_USERNAME - Имя пользователя создавшего сообщение
      AUL_CLIENT_ADR - IP адрес пользователя создавшего сообщение
      SMS_SENDER - Имя отправителя сообщения
      SMS_TARGET - Телефон адресата
      SMS_RES_COUNT - Кол-во единиц ресурсов на данное сообщение
      SMS_TEXT - Текст сообщения
      SMSSTC_CODE - Код статуса доставки сообщения
      SMS_STATUS - Текстовое описание статуса доставки сообщения
      SMS_CLOSED - [0,1] 0 - сообщения находится в процессинге. 1 = работа по отправке сообщения завершена
      SMS_SENT - [0,1] 0 - сообщение не отослано. 1 = сообщение отослано успешно
      SMS_CALL_DURATION - Время, в течение которого было установлено соединение для отправки сообщения.
      SMS_DTMF_DIGITS - Что пользователь нажимал в сеансе разговора (для SENDVOICE (в разработке))
      SMS_CLOSE_TIME - Время завершения работы по сообщению.


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
=end

    class QuickTelecom < Gateway

      CLASS_ID = 'quick_telecom'
      ALIAS = 'www.qtelecom.ru'
      SHORT_DESC = 'Шлюз sms рассылок www.qtelecom.ru'
      DESC = "Описание шлюза"

      headers 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      base_uri 'http://service.qtelecom.ru/public/http/'

      # Адреса резервных серверов: service-r1.amegainform.ru и service-r2.amegainform.ru
      # Создание нового шлюза  AmegaInformGateway
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
        response = self.class.post("#{uri}",
                                   :query => { :action => "balance"}.merge(auth_options))
        if response.code == 200
          # xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
          xml = response.body
          doc = Nokogiri::XML(xml)

          {
            :balance =>   (doc.at("//balance//AGT_BALANCE").inner_html rescue 0),
            :overdraft => (doc.at("//balance//OVERDRAFT").inner_html   rescue 0)
          }
        else
          raise
        end
      rescue
        nil
      end

      # Отправка сообщения

      # Параметры

      # * message - сообщение
      # * phones  - номера телефонов. Список через запятую. (Н-р: "+70010001212, 80009990000")
      # * sender  - имя отправителя, зарегистрированного в системе go.qtelecom.ru
      #            NULL - используется имя отправителя по умолчанию.

      # Возвращаемые параметры
      # sms_id - ид в сервисе шлюза
      # sms_count - сколько смс потрачено на отправку сообщения
      # phone - номер куда было отправлено сообщение
      # Если @errors не пустое то возвращает nil
      def deliver_sms(options = { :sender => nil})
        @options = {
          :action  => "post_sms", :message => options[:message],
          :target  => options[:phones], :sender  => options[:sender] }

        response = self.class.post("#{uri}", :query => @options.merge(auth_options))
#        xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
        xml = response.body
        if response.code == 200
          parse(xml)[:sms]
        else
          raise
        end
      rescue
        STDERR.puts  " #{$!.inspect} "
        STDERR.puts  " #{xml} " if xml
        nil
      end


      # Получение данных и статусов сообщений
      # sms_id - ид смс
      # type - sms - запрашиваем статус по одному сообщению
      #      - sms_group - запрашиваем статусы по рассылке

      # Возвращаем hash
      # где обязательно есть
      # sms_id    - ид в сервисе шлюза
      # sms_count - кол-во смс потраченное на отправку сообщения
      # phone     - телефон

      def reply_sms(sms_id, sms_type = :sms)
        raise unless [:sms, :sms_group].include?(sms_type)

        @options = { :action => "status", :smstype => "SENDSMS", "#{sms_type}_id".to_sym => sms_id }

        response = self.class.post("#{uri}", :query => @options.merge(auth_options))
#        xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
        xml = response.body
        if response.code == 200
          parse(xml)[:messages]
       else
          raise
        end
      rescue
        STDERR.puts  " #{$!.inspect} "
        STDERR.puts  " #{xml} " if xml
        false
      end

      private

      # Возвращает параметры для авторизации
      def auth_options; { :user => @login, :pass => @password }  end

      # Разбираем ответ от сервиса quick_telecom
      def parse(xml)
        doc = Nokogiri::XML(xml)
        @sms, @messages, @errors = nil, nil, nil

        # Ответ от отправка смс
        @sms = doc.at("//output//result") && doc.at("//output//result").
          children.search("//sms").map {|x|
          hash = { }
          doc.at("//output//result").each { |v,l| hash[v.downcase.to_sym] = l }
          x.each { |v,l| hash[v.downcase.to_sym] = l }
          hash[:text] = x.inner_html
          ResultSms::Result.new(hash.merge({ :sms_id => hash[:id], :sms_count => x[:sms_res_count]}))
        }

        # Сообщения о доставках смс
        @messages = doc.at("//output//MESSAGES") && doc.at("//output//MESSAGES").
          children.search("//MESSAGE").map { |x|
          hash = { }
          x.each { |v,l| hash[v.downcase.to_sym] = l }
          x.children.each {|n| hash[n.name.downcase.to_sym] = n.inner_html unless n.blank? }
          ResultSms::Message.new(hash.merge({ :phone => hash[:sms_target], :sms_count => hash[:sms_res_count] }))
        }

        # Сообщения об ошибках
        @errors = doc.at("//output//errors") && doc.at("//output//errors").
          children.search("//error").map {|x| x.inner_html }

        { :sms => @sms, :messages => @messages, :errors => @errors}
      end

      module ResultSms
        class Message < OpenStruct
          def complete; true if sms_closed.to_i == 1; end
          alias :complete? :complete

          def success; true if sms_sent.to_i == 1; end
          alias :success? :success

          def failure; true unless success?;  end
          alias :failure? :failure
          define_method(:id){ @table[:id] || object_id}
        end
        class Result  < OpenStruct
          define_method(:id){ @table[:id] || object_id}
        end
      end

    end
  end
end
