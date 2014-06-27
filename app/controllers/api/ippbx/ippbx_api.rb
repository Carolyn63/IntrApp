require 'net/http'
require 'rubygems'
require 'json'



class Api::Ippbx::Ippbx_Api< ActionController::Base
  def init(type, suffix_url, id)
    @host = property(:ippbx_server_ip)
    @port = property(:ippbx_server_port)
    if type == 'sys'
    @url = property(:ippbx_system_url) + suffix_url
    elsif type == 'sp'
    @url = property(:ippbx_serviceProvider_url) + suffix_url
    elsif type == 'ent'
    @url = property(:ippbx_enterprise_url) + suffix_url
    elsif type == 'user'
    @url = property(:ippbx_user_url) + suffix_url
    elsif type == 'search'
    @url = property(:ippbx_general_search_url) + suffix_url
    end
    if id != nil
    @url = @url + id.to_s
    end
  end

  def get(user, pass, type, suffix_url, id)
    init(type, suffix_url, id)
    req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth user, pass
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("get", nil, response)
    return response
  end

  def post(user, pass, type, suffix_url, json_content)
    init(type, suffix_url, nil)
    logger.info "Post Json: #{json_content}"
    req = Net::HTTP::Post.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth user, pass
    req.body = json_content
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("get", nil, response)
    return response
  end

  def put(user, pass, type, suffix_url, json_content)
    init(type, suffix_url, nil)
    logger.info "put Json: #{json_content}"
    req = Net::HTTP::Put.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth user, pass
    req.body = json_content
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("get", nil, response)
    return response
  end

  def delete(user, pass, type, suffix_url, id)
    init(type, suffix_url, id)
    req = Net::HTTP::Delete.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth user, pass
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("get", nil, response)
    return response
  end

  private

  def format_http_response(res)
    response = res
    unless response.code == '200'
      begin
        temp_res_code = "[" + response.body.split(",")[0].split(":")[1].strip + "]"
        temp_res_err_msg = response.body.split(",")[1].split(":", 2)[1].strip
        temp_res_err_type = response.body.split(",")[2].split(":", 2)[1].strip
        response.body[0..-1] = temp_res_err_type[1..temp_res_err_type.rindex('"')-1] +" "+ temp_res_err_msg[1..temp_res_err_msg.rindex('"')-1] +" "+ temp_res_code
      rescue
      response = res
      end
    end
    return response
  end

  private

  def send_log(method, json_content, response)
    logger.info "========================Calling IP PBX API========================"
    logger.info "Method: #{method.upcase}"        
    logger.info "Url: #{@url}"
    logger.info "Posts Json String: #{json_content}" if method.upcase == "POST"
    logger.info "Puts Json String: #{json_content}" if method.upcase == "PUT"
    logger.info "Response Http Code: #{response.code}"    
    if response.code == '200'    
    logger.info "Status: Successfully"
    elsif
    logger.error "Status: Failed!"
    logger.error "Failure Reason: #{response.body}"
    end
    logger.info "=================================================================="
  end

end