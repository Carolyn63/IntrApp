  paypal_user_id = "softes_1332940240_biz@gmail.com"
  paypal_password = "P4QKZSWWLHAY8UEM"
  paypal_signature =  "AbVoe7ZYr9G-7whCdh8yFM4uePDRAQf6O7-JPUkUMyV0510dTasv3Jdd"
  api_url = 'https://api-3t.sandbox.paypal.com'
   @params = {
  'USER' => urlencode(paypal_user_id),
  'PWD' => urlencode(paypal_password),
  'SIGNATURE' => urlencode(paypal_signature),
  'VERSION' => urlencode('51.0'),
  'METHOD' => urlencode('ManageRecurringPaymentsProfileStatus'),
  'PROFILEID' => urlencode("I-79KSMCFEH8V6"),
  'ACTION' => urlencode('Cancel'),
  }
  
         @query_params = ''
         @params.each_pair {|key, value| @query_params = @query_params + '&' + key + '=' + value}
         logger.info "IPN QUERY: #{@query_params}"
         #POST this data
         uri = URI.parse(api_url)
         http = Net::HTTP.new(uri.host, uri.port)
         http.use_ssl = true
         response = http.post('/nvp' , @query_params)
         logger.info response.body 
