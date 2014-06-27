class AmazonApi < ActionController::Base
###############################################################################
 #  Copyright 2008-2010 Amazon Technologies, Inc
 #  Licensed under the Apache License, Version 2.0 (the "License");
 #
 #  You may not use this file except in compliance with the License.
 #  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
 #  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 #  CONDITIONS OF ANY KIND, either express or implied. See the License for the
 #  specific language governing permissions and limitations under the License.
 ##############################################################################

require 'uri'
require 'time'
require 'signatureutils'

  #Set these values depending on the service endpoint you are going to hit
  @@app_name = "FPS"
  @@http_method = "GET"
  @@service_end_point = "https://fps.amazonaws.com/"
  @@version = "2008-09-17"

  @@access_key = "AKIAJ3ILQUB24EHRPNAQ"
  @@secretKey = "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"

  def self.get_fps_default_parameters()
    parameters = {}
    parameters["Version"] = @@version
    parameters["Timestamp"] = get_formatted_timestamp()
    parameters["AWSAccessKeyId"] = @@access_key  

    return parameters
  end

  def self.get_fps_url(params)
    fpsURL = @@service_end_point + "?"
    isFirst = true
    params.each { |k,v|
      if(isFirst) then
        isFirst = false
      else
        fpsURL << '&'
      end

      fpsURL << Amazon::FPS::SignatureUtils.urlencode(k)
      unless(v.nil?) then
        fpsURL << '='
        fpsURL << Amazon::FPS::SignatureUtils.urlencode(v)
      end
    }
    return fpsURL
  end 
  
  def self.get_formatted_timestamp()
    return Time.now.iso8601.to_s
  end

  def self.get_amazon_url(action, transaction_id)
    logger.info("111111111111111111111")
    uri = URI.parse(@@service_end_point)

   
    #  Version 2 - Current approach of signing requests
    parameters = get_fps_default_parameters()
    #Sample GetTransactionStatusRequest
    parameters["Action"] = action
    if parameters["Action"] == "cancel"
    parameters["SubscriptionId"] = transaction_id
    else
    parameters["TransactionId"] = transaction_id
    end
    
    parameters[Amazon::FPS::SignatureUtils::SIGNATURE_VERSION_KEYNAME] = "2"
    parameters[Amazon::FPS::SignatureUtils::SIGNATURE_METHOD_KEYNAME] = Amazon::FPS::SignatureUtils::HMAC_SHA256_ALGORITHM
    signature = Amazon::FPS::SignatureUtils.sign_parameters({:parameters => parameters, 
                                            :aws_secret_key => @@secretKey,
                                            :host => uri.host,
                                            :verb => @@http_method,
                                            :uri  => uri.path })
    parameters[Amazon::FPS::SignatureUtils::SIGNATURE_KEYNAME] = signature
    logger.info(get_fps_url(parameters))
    return get_fps_url(parameters)
 end

def self.post_amazon(action, id)
  begin
  url = get_amazon_url(action,id)
  uri = URI.parse('https://fps.sandbox.amazonaws.com')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.post(url , "")
  return response
  rescue
  return ""
  end
end

#Amazon::FPS::FPSAPISampleCode::test()



end


  
