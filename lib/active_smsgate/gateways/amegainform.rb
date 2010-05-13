# -*- coding: utf-8 -*-
module ActiveSmsgate #:nodoc:
  module Gateway #:nodoc:

=begin rdoc
   «Амега Информ» – http://amegainform.ru/
   это сервис  массовой рассылки, приема SMS и голосовых сообщений.

      # Возвращаемые данные
      # <output>
      # <result sms_group_id="996">
      # <sms id="99991" smstype="SENDSMS" phone="+79999999991" sms_res_count="1"><![CDATA[Привет]]></sms>
      # <sms id="99992" smstype="SENDVOICE" phone="+79999999992" sms_res_count="38"><![CDATA[%PAUSE=1000%%SYNTH=Vika%Привет друг%SAMPLE=#1525%%PAUSE=1000%%SYNTH=Vika%С днём рождения!]]></sms>
      # </result>
      # <output>


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
    class Amegainform < Gateway

      CLASS_ID = 'amegainform'
      ALIAS = 'www.amegainform.ru'
      SHORT_DESC = 'Шлюз sms рассылок www.amegainform.ru'
      DESC = "Описание шлюза"

      headers 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      base_uri 'http://service.amega-inform.ru'

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
        response = self.class.post("#{uri}/sendsms",
                                    :query => { :action => "balance"}.merge(auth_options))
        if response.code == 200
          xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
          doc = Nokogiri::XML(xml)
          {
            :balance =>   (doc.at("//balance//AGT_BALANCE").inner_html rescue 0),
            :debt =>      (doc.at("//balance//PARENT_DEBT").inner_html rescue 0),
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
      # * sender  - имя отправителя, зарегистрированного в системе service.amegainform.ru.
      #            NULL - используется имя отправителя по умолчанию.

      # Возвращаемые параметры
      # sms_id - ид в сервисе шлюза
      # sms_count - сколько смс потрачено на отправку сообщения
      # phone - номер куда было отправлено сообщение
      # Если @errors не пустое то возвращает nil
      def deliver_sms(options = { :sender => nil})
        @options = {
          :action  => "post_sms", :message => options[:message],
          :target  => options[:phones],
          :sender  => options[:sender] }

        response = self.class.post("#{uri}/sendsms", :query => @options.merge(auth_options))
        xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
        if response.code == 200
          parse(xml)
          @sms.map{|x| x.merge({ :sms_group_id => x[:sms_group_id],
                                 :sms_id => x[:id], :phone => x[:phone], :sms_count => x[:sms_res_count] })}

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

        @options = { :action => "status", :sendtype => "SENDSMS", "#{sms_type}_id" => sms_id }
        response = self.class.post("#{uri}/sendsms", :query => @options.merge(auth_options))
        xml = Zlib::GzipReader.new( StringIO.new( response ) ).read
        if response.code == 200
          parse(xml)
          if sms_type == :sms
            @messages.map{ |msg| msg.merge({ :sms_id => msg[:sms_id],:sms_count => msg[:sms_res_count],
                                             :phone => msg[:sms_target] }) }.find{ |x| x[:sms_id] ==  sms_id.to_s }
          else
            @messages.map{ |msg| msg.merge({ :sms_id => msg[:sms_id],
                                             :sms_count => msg[:sms_res_count], :phone => msg[:sms_target] }) }
          end
        else
          raise
        end
      rescue
        STDERR.puts  " #{$!.inspect} "
        STDERR.puts  " #{xml} " if xml
        false
      end

      # Выполнение отправки смс завершено
      def complete_sms(sms_id)
        @message ||= reply_sms(sms_id)
        true if @message[:sms_closed].to_i == 1
      end
      alias :complete_sms? :complete_sms

      # Смс досталена
      def success_sms(sms_id)
        @message ||= reply_sms(sms_id)
        true if @message[:sms_sent].to_i == 1
      end
      alias :success_sms? :success_sms

      # Смс не доставлена
      def failure_sms(sms_id)
        @message ||= reply_sms(sms_id)
        true if @message[:sms_sent].to_i != 1
      end
      alias :failure_sms? :failure_sms

      private

      # Возвращает параметры для авторизации
      def auth_options; { :user => @login, :pass => @password }  end

      # Разбираем ответ от сервиса amegainform
      def parse(xml)
        doc = Nokogiri::XML(xml)
        @sms, @messages, @errors = nil, nil, nil
        # Ответ от отправка смс
        @sms = doc.at("//output//result") && doc.at("//output//result").
          children.search("//sms").map {|x|
          _x ={}
          doc.at("//output//result").each { |v,l| _x[v.downcase.to_sym] = l }
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
