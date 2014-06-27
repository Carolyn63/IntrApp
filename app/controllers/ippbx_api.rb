class IppbxApi < ActionController::Base

  # /*
  # * method: IppbxApi.ippbx_get, IppbxApi.ippbx_post, IppbxApi.ippbx_put, IppbxApi.ippbx_delete, ippbx_search
  # * variable parameter: *params
  # * each method can accept 3 or 5 parameters
  # * params[0]: username; optional
  # * params[1]: password; optional
  # * params[2]: level; values {'sys','sp','ent','user'}; compulsory
  # * params[3]: location; compulsory
  # * params[4]: criteria(search) || id(delete) || factor(get) || json_str(put & post); compulsory
  # */
 
  def self.ippbx_search(*params)
    #use method with 3 params
    if params.count == 3
    init(params[0], params[1], params[2], true)
    #use method with 5 params
    elsif params.count == 5
    init(params[2], params[3], params[4], true)
    end
    @user = params[0] and @pass = params[1]
    req = Net::HTTP::Get.new(@path, initheader = {'Content-level' =>'application/json'})
    req.basic_auth @user, @pass
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("search", nil, response)
    return response
  end

  def self.ippbx_get(*params)
    #use method with 3 params
    if params.count == 3
    init(params[0], params[1], params[2], false)
    #use method with 5 params
    elsif params.count == 5
    init(params[2], params[3], params[4], false)

    end
    @user = params[0] and @pass = params[1]
    req = Net::HTTP::Get.new(@path, initheader = {'Content-level' =>'application/json'})
    req.basic_auth @user, @pass
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("get", nil, response)
    return response
  end

  def self.ippbx_post(*params)
    if params.count == 3
    init(params[0], params[1], nil, false)
    json_str = params[2]
    elsif params.count == 5
    init(params[2], params[3], nil, false)

    json_str = params[4]
    end
    @user = params[0] and @pass = params[1]
    req = Net::HTTP::Post.new(@path, initheader = {'Content-level' =>'application/json'})
    req.basic_auth @user, @pass
    req.body = json_str
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("post", params[4], response)
    return response
  end

  def self.ippbx_put(*params)
    if params.count == 3
    init(params[0], params[1], nil, false)
    json_str = params[2]
    elsif params.count == 5
    init(params[2], params[3], nil, false)
    json_str = params[4]
    end
    @user = params[0] and @pass = params[1]
    req = Net::HTTP::Put.new(@path, initheader = {'Content-level' =>'application/json'})
    req.basic_auth @user, @pass
    req.body = json_str
    response = format_http_response(Net::HTTP.new(@host, @port).start {|http| http.request(req)})
    send_log("put", params[4], response)
    return response
  end

  def self.ippbx_delete(*params)
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
    return response
  end

  private

  def self.init(level, location, misc, is_search)
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
    elsif level == 'voip'
    prefix = property(:ippbx_voip_url)
    elsif level == 'vm'
    prefix = property(:ippbx_vm_url)
    end

    if is_search
    prefix = property(:ippbx_general_search_url)
    end

    @path = prefix + location + misc

  end

  private

  def self.format_http_response(res)
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

  private

  def self.send_log(method, json_str, response)
    logger.info "========================Calling IP PBX API========================"
    logger.info "Method: #{method.upcase}"
    logger.info "Url: #{@path}"
    # logger.info "level: #{@user}"
    logger.info "Username: #{@user}"
    logger.info "Password: #{@pass}"
    logger.info "Posts Json String: #{json_str}" if method.upcase == "POST"
    logger.info "Puts Json String: #{json_str}" if method.upcase == "PUT"
    logger.info "Response Http Code: #{response.code}"
    if response.code == '200'
    logger.info "Status: Successfully"
    logger.info "Response Body: #{response.body}"
    elsif
    logger.error "Status: Failed!"
    logger.error "Failure Reason: #{response.body}"
    end
    logger.info "=================================================================="
  end

end
