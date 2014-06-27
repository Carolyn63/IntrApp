class VoipController < ApplicationController
  def index
    @api_result
  end

  def update
    ippbx = Ippbx.find_by_employee_id(params[:employee_id])
    content_json = {"callingNumber" => ippbx.public_number,"calledNumber" => params[:calledNumber],
      "remoteHost" => property(:voip_remotehost),"remotePort" => '80',  "contextName" => 'hips'}.to_json
    ippbx_call_user = ippbx.login
    ippbx_call_pass =Tools::AESCrypt.new.decrypt(ippbx.password)
    response = IppbxApi.ippbx_put(ippbx_call_user, ippbx_call_pass, 'voip', '', content_json)
    if response.code == '200'
      session[:subsription_id] =  get_subscription_id(response)
      params_fields = {:subscription_id => session[:subsription_id],:uid => ippbx.uid}
      @calls = Call.new(params_fields)
      if @calls.save
      logger.info "subscription id = #{session[:subsription_id]} with uid = #{ippbx.uid} is saved into calls database table"
      end
    @api_result = session[:subsription_id]
    logger.info "**********************subsription iddd: #{session[:subsription_id]}"
    else
    #@api_result = response.body
    flash[:error]  = t("controllers.update.error.password") + "<br />" + response.body
    end

  #return @api_result;
  #redirect_to user_path(params[:user_id])
  end

  def get_voip_event_code
    subscription_id = params[:sid]
    calls = Call.find_by_subscription_id(subscription_id)
    @api_result = calls.event_code
     logger.info "**********************@api_result: #{@api_result}"
   #render :action => :index
  end

	def delete_sid
		subscription_id = params[:sid]
		calls = Call.find_by_subscription_id(subscription_id) and ippbx = Ippbx.find_by_uid(calls.uid)
		ippbx_call_user = ippbx.login
		ippbx_call_pass =Tools::AESCrypt.new.decrypt(ippbx.password)

		response = IppbxApi.ippbx_delete(ippbx_call_user, ippbx_call_pass, 'voip', '/',subscription_id)
			@api_result = ""
		if response.code == '200'
			ActiveRecord::Base.connection.execute("delete from calls where subscription_id='"+subscription_id+"'")
			@api_result = "call finished"
		end
		logger.info "***********Subscription ID #{subscription_id} is deleted"
  end

  # def destroy
  # #delete subscription id when recieving call end event
  # if session[:subsription_id]
  # ippbx = Ippbx.find_by_employee_id(params[:employee_id])
  # ippbx_call_user = ippbx.login
  # ippbx_call_pass =Tools::AESCrypt.new.decrypt(ippbx.password)
  #
  # response = IppbxApi.ippbx_delete(ippbx_call_user, ippbx_call_pass, 'voip', '/',session[:subsription_id])
  # if response.code == '200'
  # @api_result = "Delete subcsription Id, " +session[:subsription_id]+ " OK, Http Code = " + response.code
  # session[:subsription_id] = nil
  # else
  # @api_result = "Delete subcsription Id, " +session[:subsription_id]+ " Failed, Http Code = " + response.code
  # end
  # logger.info "**********************api_result:#{@api_result }"
  # end
  # #render :action => :index
  # end

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

  private

  def get_subscription_id(res)
    response = res
    if response.code == '200'
      begin
        response = response.body.split(":\"")[1].split("\"}")[0]
      rescue
      response = res
      end
    end
    return response
  end

end
