
require 'net/http'
require 'uri'
require 'xmlsimple'
require "base64"

module Services
  module MobileTribe
    class Connector

      @@api_base = property(:mobile_tribe_api)
      @@serviceProvider = property(:serviceProvider)
      
      def initialize options = {}
        @mt_application_key = options[:mt_application_key] || "MTabcdef"
        @request_hash = { 'MT-Application-Key' => @mt_application_key,
                          'feature' => 'mtcontrol',
                          'portal'  => 'mobiletribe',
                          'serviceProvider' => @@serviceProvider,
                          'version' => '1' }
        @basic_auth = {}
        @need_encode_password_fields = options[:need_encode_password_fields] || false
        @logger = Tools::ApiLogger.new :name => options[:log_name] || "mobiletribe"
      end
      
      def register_user options = {}
        @logger.start_logging
        #puts options.inspect
        @logger.put "Create user"
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => "RegisterUser" ) )
        #puts xml_values.inspect
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end
      
      def create_user options = {}
        @logger.start_logging
        #puts options.inspect
        @logger.put "Create user"
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => "CreateUser" ) )
        #puts xml_values.inspect
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      def create_friendship options = {}
        @logger.start_logging
        #puts options.inspect
        @logger.put "Create Friendship"
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => "CreateFriend" ) )
        #puts xml_values.inspect
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end


      def create_department options = {}
         @logger.start_logging
         @logger.put "Create department"
         xml_values = request_by_get ( @@api_base, encode_password_fields!(options).merge ('operation' => "CreateDepartment") )
         @logger.put "Answer: #{xml_values.inspect}"
         @logger.stop_logging
         raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      def create_company options = {}
  
        @logger.start_logging
        #puts options.inspect
        @logger.put "Create company"
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => "CreateCompany" ) )
    
        #puts xml_values.inspect
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      
      def create_employee options = {}
        @logger.start_logging
        #puts options.inspect
        @logger.put "Create Employee"
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => "CreateEmployee" ) )
        #puts xml_values.inspect
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

#      def login options = {}
#        @logger.put "Login"
#        #userID=someUserName&password=TestPassword
#        xml_values = request_by_get( @@api_base, options.merge( "operation" => "Login" ) )
#        @logger.put "Answer #{xml_values.inspect}"
#        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"] == "error"
#      end
      
      def register_credentials login, password, options = {}
        @logger.start_logging
        @logger.put "Register portal credentials"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'RegisterPortal',
                                                                 'portalName' => 'ebento'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end

      def update_company options = {}
        @logger.start_logging
        @logger.put "Update Company Status"
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'EditCompany'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
      end

      def update_department options = {}
        @logger.start_logging
        @logger.put "Update Department Status"
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'EditDepartment'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
      end
      
       def update_friendship options = {}
        @logger.start_logging
        @logger.put "Update Friendship"
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'ChangeFriendStatus'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
      end

      def update_employee options = {}
        @logger.start_logging
        @logger.put "Update Employee Status"
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'EditEmployee'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
      end

      def update_user login, password, options = {}
        @logger.start_logging
        @logger.put "Update User Status"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'EditUser'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        #raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end
      
      
      def modify_user login, password, options = {}
        @logger.start_logging
        @logger.put "Update User Status"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, options.merge('operation' => 'ModifyUser'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        #raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      def change_user_password login, password, options = {}
        @logger.start_logging
        @logger.put "Change user password"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'ChangePassword'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end
        
      def create_c2call login, password, options = {}
        @logger.start_logging
        @logger.put "C2Call create"
        @basic_auth = {:user => login, :password => password}
        mail_options = options.merge('portalPassword' => options["crypted_password"])
        @logger.put "Options #{options.inspect}"
        mail_options.delete("crypted_password").delete("password")
        xml_values = request_by_get( @@api_base, encode_password_fields!(mail_options).merge( 'operation' => 'RegisterPortal',
                                                                     'portalName' => 'c2call'))
        @logger.put "Answer C2Call #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end
      
      def create_calendar_and_mail login, password,  options = {}
        @logger.start_logging
        @logger.put "Mail create"
        @basic_auth = {:user => login, :password => password}
        mail_options = options.merge('portalPassword' => options["crypted_password"])
        @logger.put "Options #{options.inspect}"
        mail_options.delete("crypted_password").delete("password")
        xml_values = request_by_get( @@api_base, encode_password_fields!(mail_options).merge( 'operation' => 'RegisterPortal',
                                                                     'portalName' => 'corporatemail'))
        @logger.put "Answer mail #{xml_values.inspect}"
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
        @logger.put "Calendar create"
        calendar_options = options.merge('portalPassword' => password)
        calendar_options.delete("crypted_password").delete("password")
        xml_values = request_by_get( @@api_base, encode_password_fields!(calendar_options).merge('operation' => 'RegisterPortal',
                                                                        'portalName' => 'corporatecalendar'))
        @logger.put "Answer calendar #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end

      def remove_calendar_and_mail login, password, options = {}
        @logger.start_logging
        @logger.put "Remove calendar and mail"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, options.merge( 'operation' => 'UnregisterPortal',
                                                                'portalName' => 'corporatemail'))
        xml_values = request_by_get( @@api_base, options.merge( 'operation' => 'UnregisterPortal',
                                                                'portalName' => 'corporatecalendar'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end

      def contacts_or_friends_update options = {}
        @logger.start_logging
        @logger.put "Contact or friends update"
        xml_values = request_by_get( @@api_base, options.merge( 'operation' => 'EbentoDataUpdated',
                                                                'portal' => 'ebento',
                                                                'feature' => 'notifications'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end

      def remove_association login, password, options = {}
        @logger.start_logging
        @logger.put "Remove association"
        @basic_auth = {:user => login, :password => password}
        xml_values = request_by_get( @@api_base, options.merge( 'operation' => 'UnregisterPortal',
                                                                'portalName' => 'ebento'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["message"] ) if xml_values["status"].to_s == "error"
      end

      def destroy_user options = {}
        @logger.start_logging
        @logger.put "Remove User"
        #@basic_auth = {:user => login}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'DeleteUser'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end
      def destroy_friendship options = {}
        @logger.start_logging
        @logger.put "Remove Friendship"
        #@basic_auth = {:company_id => company}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'DeleteFriend'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end
      
     def destroy_employee options = {}
        @logger.start_logging
        @logger.put "Remove Employee"
        #@basic_auth = {:company_id => company}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'DeleteEmployee'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      def destroy_department options = {}
        @logger.start_logging
        @logger.put "Remove Department"
        #@basic_auth = {:company_id => company}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'DeleteDepartment'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      def destroy_company options = {}
        @logger.start_logging
        @logger.put "Remove Company"
        #@basic_auth = {:company => company_id}
        xml_values = request_by_get( @@api_base, encode_password_fields!(options).merge( 'operation' => 'DeleteCompany'))
        @logger.put "Answer #{xml_values.inspect}"
        @logger.stop_logging
        raise Services::MobileTribe::Errors::GenerickError.new( xml_values["resultText"] ) if xml_values["resultCode"].to_s != "0"
      end

      private
        def request_by_get( action, additional_parameters = {} )
          begin
            params = {:headers => {"params" => @request_hash.merge( additional_parameters )},
                      :timeout => 600,
                      :open_timeout => 10}
            params.merge!(@basic_auth) unless @basic_auth.blank?
            puts params.inspect
            puts @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Params #{params.inspect} #{@request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")}"
            resource = RestClient::Resource.new action, params
            body = resource.get
            @logger.put "Body #{body.inspect}"
            values = XmlSimple.xml_in( body, { 'ForceArray' => false } )
          rescue RestClient::NotImplemented => e
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Body:\n" + e.http_body
            @logger.stop_logging
            raise Services::MobileTribe::Errors::GenerickError.new ("I must have sent something wrong to the server. Can you try again?" )
          rescue RestClient::InternalServerError => e
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            RAILS_DEFAULT_LOGGER.info "Body:\n" + e.http_body
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Body:\n" + e.http_body
            @logger.stop_logging
            raise Services::MobileTribe::Errors::GenerickError.new( "Oops, looks like something went wrong..." )
          rescue RestClient::Unauthorized, RestClient::BadGateway => e
            puts e.inspect
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            RAILS_DEFAULT_LOGGER.info "Body:\n" + e.http_body
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Body:\n" + e.http_body
            @logger.stop_logging
            raise Services::MobileTribe::Errors::Unauthorized.new ()
          rescue Exception, Timeout::Error => e
            puts e.inspect
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            @logger.put "Was requested:\n" + action + "?" + @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            @logger.stop_logging
            raise Services::MobileTribe::Errors::GenerickError.new( "I couldn't connect to our servers. Maybe something is wrong?" )
          end
        end

        def encode_password_fields!(options)
          if @need_encode_password_fields
            ["mtUserPassword", "portalPassword", "newPassword"].each do |key|
              options[key] = Base64.encode64(options[key]).strip.delete("\n") if options.has_key?(key)
            end
          end
          options
        end
=begin
### first implementation      
        def request_by_get( action, additional_parameters = {} )
          url = URI.parse(  action )
          puts @request_hash.merge( additional_parameters ).inspect
          data = @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
          
          begin
            http = Net::HTTP.new( url.host, url.port )
            http.use_ssl = true
            res = http.post( url.path, data, {} )
          rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
            Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            puts e.inspect
            puts e.body
          end
          puts res.body
          case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            puts res.body
          else
            #res.error!
          end
        end
=end        
    end    
  end
end
