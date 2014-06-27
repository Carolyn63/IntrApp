class PaypalApi < ActionController::Base

def self.cancel_payment paypal_params
      paypal_user_id = property(:paypal_api_user_id)
      paypal_password =  property(:paypal_api_password)
      paypal_signature =   property(:paypal_api_signature)
      
      params_hash = {
          'USER' => paypal_user_id,
          'PWD' => paypal_password,
          'SIGNATURE' => paypal_signature,
          'VERSION' => '51.0',
          'METHOD' => 'ManageRecurringPaymentsProfileStatus',
          'PROFILEID' => "#{paypal_params[:subscription_id]}",
          'ACTION' => 'Cancel'
          }
      query_params = ''
      params_hash.each_pair {|key, value| query_params = query_params + '&' + key + '=' + value}
      response = paypal_post query_params
      return response
end


def self.refund_payment paypal_params
    paypal_user_id = property(:paypal_api_user_id)
    paypal_password =  property(:paypal_api_password)
    paypal_signature =   property(:paypal_api_signature)
    params_hash = {
        'USER' => paypal_user_id,
        'PWD' => paypal_password,
        'SIGNATURE' => paypal_signature,
        'VERSION' => '51.0',
        'METHOD' => 'RefundTransaction',
        'TRANSACTIONID' => "#{paypal_params[:transaction_id]}",
        'REFUNDSOURCE' => 'any'
        }
     query_params = ''
     params_hash.each_pair {|key, value| query_params = query_params + '&' + key + '=' + value}
     response = paypal_post query_params
     return response
end

def self.paypal_post query_params
   paypal_api_url = 'https://api.sandbox.paypal.com'
   response_message = ""
          #paypal_api_url = property(:paypal_api_url)
    begin
        uri = URI.parse(paypal_api_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.post('/nvp' , query_params)
        logger.info response.body
        response_message = format_response(response.body)
    rescue
    end
    logger.info(response_message)
    return response_message
end

def self.format_response reponse_body
    response_header = ""
    response_message = ""
    response_array = reponse_body.split("&")
    response_array.each do |response|
    if response.include? "ACK"
        response_header, response_message = response.split("=")
	break
    end
    end
    return response_message
  
end

end


  
