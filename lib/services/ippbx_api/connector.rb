
require 'net/http'
require 'uri'
require 'xmlsimple'
require "base64"
require "json"

module Services
  module IppbxApi
    class Connector
      
      def initialize options = {}
       @logger = Tools::ApiLogger.new :name => options[:log_name] || "development"
        #@logger = Tools::ApiLogger.new :name => "development"
      end
     
    def ippbx_delete(*params)
    @logger.start_logging
    if params.count == 3
    init(params[0], params[1], params[2], false)
    elsif params.count == 5
    init(params[2], params[3], params[4], false)
    end
    @user = params[0] and @pass = params[1]
    req = Net::HTTP::Delete.new(@path, initheader = {'Content-level' =>'application/json'})
    req.basic_auth @user, @pass
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("delete", nil, response)
    @logger.stop_logging
    return response
  end

    def init(level, location, misc, is_search)
    prefix ||= "" and location ||= "" and misc ||= ""
    @host = property(:ippbx_server_ip)
    @port = property(:ippbx_server_port)
    if level == 'sys'
    prefix = property(:ippbx_system_url)
    elsif level == 'sp'
    prefix = property(:ippbx_serviceProvider_url)
    elsif level == 'ent'
    prefix = property(:ippbx_enterprise_url)
    elsif level == 'user'
    prefix = property(:ippbx_user_url)
    end

    if is_search
    prefix = property(:ippbx_general_search_url)
    end

    @path = prefix + location + misc

  end

      
  def format_http_response(res)
    response = res
    unless response.code == '200'
      begin
        statusCode = "[" + response.body.split(",\"errorMessage\":\"")[0].split(":")[1].strip + "]"        
        errorMessage = response.body.split(",\"errorMessage\":\"")[1].split("\",\"statusMessage\":\"")[0].strip        
        statusMessage = response.body.split("\",\"statusMessage\":\"")[1].split("\"}")[0].strip        
        response.body[0..-1] = statusMessage +" "+ errorMessage +" "+ statusCode
      rescue
      response = res
      end
    end
    return response
  end
  
  def send_log(method, json_str, response)
    @logger.put "========================Calling IP PBX API========================"
    @logger.put"Method: #{method.upcase}"
    @logger.put "Url: #{@path}"
    # logger.info "level: #{@user}"
    @logger.put "Username: #{@user}"
    @logger.put "Password: #{@pass}"
    @logger.put "Posts Json String: #{json_str}" if method.upcase == "POST"
    @logger.put "Puts Json String: #{json_str}" if method.upcase == "PUT"
    @logger.put "Response Http Code: #{response.code}"
    if response.code == '200'
    @logger.put "Status: Successfully"
    elsif
    @logger.put "Status: Failed!"
    @logger.put "Failure Reason: #{response.body}"
    end
    @logger.put"=================================================================="
  end
      
      
      
      
      
      
      
      
    end
   end
end
