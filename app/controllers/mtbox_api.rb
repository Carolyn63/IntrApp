require 'rubygems'
#require 'mechanize' #will be enabled after installing ruby 1.8.7+



class MtboxApi < ActionController::Base
  def self.create_suffix(action, key)
    @suffix = "/api/1.0/rest?action="
    if action == "get_ticket"
    @action_url = @suffix + "get_ticket&api_key=" + property(:mtbox_api_key)
    elsif action == "get_auth_token"
    @action_url = @suffix + "get_auth_token&api_key=" + property(:mtbox_api_key) + "&ticket=" + key
    #elsif action == "create_user"
    #@action_url = @suffix + "register_new_user&api_key=" + property(:mtbox_api_key) + "&ticket=" + key + "&login=" + user + "&password=" +pass
    end
  end

  def self.get_mt_box(action,key)
    @server_url = property(:box_server_url)
    create_suffix(action, key)
    @url = @server_url + @action_url
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.start do |http|
      req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/xml'})
      response = http.request(req)
      response_hash = Hash.from_xml(response.body)
      print_log(action,response.code)
      return response_hash
    end
  end

  def self.mtbox_login(ticket,user,pass)
    logger.info('------------------------------------------------------------')
    loginurl = "https://m.box.net/api/1.0/auth/"+ticket
    agent = Mechanize.new
    page = agent.get(loginurl)
    my_page = page.form_with(:action => loginurl) do |form|
      form.login = user
      form.password = pass
    end.submit
    logger.info("Logged in as #{user}")
    logger.info('------------------------------------------------------------')
  end
  
  def self.print_log(action,response)
  logger.info('------------------------------------------------------------')
  logger.info"MT Box Api Call for #{action}"
  logger.info("Response Code #{response}")
  logger.info("Success") if response == '200'
  logger.info('------------------------------------------------------------')
  end
end
