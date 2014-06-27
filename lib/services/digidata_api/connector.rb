require 'net/http'
require 'uri'
require 'xmlsimple'
require "base64"
require "json"

module Services
  module DigidataApi
    class Connector
      def initialize options = {}
        @logger = Tools::ApiLogger.new :name => options[:log_name] || "development"
        #@logger = Tools::ApiLogger.new :name => "development"
        #@url = "http://core5demo.digidatagrid.com/otogo/rest/"
        @url = "http://core5demo.digidatagrid.com/otogo/rest/"
      end

      def digidata_get_xml(*params)
        @logger.start_logging
        level = params[2]
        @url = @url + level
        uri = URI.parse(@url)
        #logger.info "uri #{uri}"

        @user = params[0]
        @pass = params[1]
        #xml_str = params[3]
        #@logger.put "url #{@url}"

        req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/vnd.com.digidata.ddvs+xml;v=1', 'Accept' =>'application/vnd.com.digidata.ddvs+xml;v=1'})
        req.basic_auth @user, @pass
        #req.body = xml_str
        response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req)}
        @logger.put "response #{response.body}"
        @logger.put "code #{response.code}"
        @logger.put "url #{@url}"
        @logger.stop_logging
        return response
      end

      def digidata_post_xml(*params)
        @logger.start_logging
        level = params[2]
        @url = @url + level
        uri = URI.parse(@url)
        #logger.info "uri #{uri}"

        @user = params[0]
        @pass = params[1]
        xml_str = params[3]
        @logger.put "url #{@url}"

        req = Net::HTTP::Post.new(@url, initheader = {'Content-Type' =>'application/vnd.com.digidata.ddvs+xml;v=1', 'Accept' =>'application/vnd.com.digidata.ddvs+xml;v=1'})
        req.basic_auth @user, @pass
        req.body = xml_str
        response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req)}
        @logger.put "response #{response.body}"
        @logger.put "code #{response.code}"
        @logger.put "url #{@url}"
        @logger.stop_logging
        return response
      end

      def digidata_post_json(*params)
        @logger.start_logging
        level = params[2]
        @url = @url + level
        uri = URI.parse(@url)
        @user = params[0]
        @pass = params[1]
        json_str = params[3]
        @logger.put "url #{@url}"

        req = Net::HTTP::Post.new(@url, initheader = {'Content-Type' =>'application/vnd.com.digidata.ddvs+json;v=1', 'Accept' =>'application/vnd.com.digidata.ddvs+json;v=1'})
        req.basic_auth @user, @pass
        req.body = json_str
        response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req)}
        @logger.put "response #{response.body}"
        @logger.put "code #{response.code}"
        @logger.put "url #{@url}"
        @logger.stop_logging
        return response
      end
    end
  end
end
