<h1> Test Script<h1>

<%
require 'SignatureUtilsForOutbound'

utils = SignatureUtilsForOutbound.new();

params = {"recurringFrequency"=>"1 MONTH", "paymentReason"=>"Monthly Subscription for Hosted IP PBX Service,Hosted Cloud Storage Service,Hosted Apps Service", "buyerName"=>"Jeong-Ho Lee", "signatureVersion"=>"2", "action"=>"create", "transactionAmount"=>"USD 1.00", "subscriptionId"=>"b43be299-03de-4f8b-8e60-7ff8d5d37467", "recipientName"=>"Mobile Tribe", "noOfPromotionTransactions"=>"0", "signature"=>"BHjhkqGTYZLGe2QEPn0wHCFKA6Phvaspyp0oOQl8EeOvRNdM1iUUi3jKj9NHAefhQR3mQbRmK/XU\nZMbICvnZmDIVQc1LC9snKwNkuanTkisRNUDBD/0fJADOLLzr3wjUSR4SNw7P24n3MeK+pMt72QCp\nFsSgOW867nZSgiOuRT4=", "certificateUrl"=>"https://fps.sandbox.amazonaws.com/certs/090911/PKICert.pem?requestId=15nc84ixx8iz1zkd0duc415hn8jtmyfjbw5kb09eemddet4", "signatureMethod"=>"RSA-SHA1", "recipientEmail"=>"gvanecek@mobiletribe.net", "startValidityDate"=>"1336055629", "controller"=>"ipn/amazon", "referenceId"=>"10001,10002,10003", "status"=>"SubscriptionSuccessful", "buyerEmail"=>"junewhee@googlemail.com", "paymentMethod"=>"CC", "email"=>"qweeti.n.g@gmail.com", "subscriptionPeriod"=>"999 MONTH"}


#=begin
params.delete("email")
params.delete("controller")
if !params[:company_id].blank?
company_id = params[:company_id]
params.delete("company_id")
end
#

begin
	url_end_point = property(:app_site) + "/ipn/amazon"

	response = utils.validate_request(:parameters => params, :url_end_point => url_end_point, :http_method => "POST")
rescue Exception => e
%>
Error: Amazon transaction <%=e.message%>
<%
end
=end


#require 'date'
=begin
payment_date = "01:09:43 Apr 05, 2012 PDT"
#puts "payment_date: #{payment_date}"
parseDate = DateTime.parse(payment_date)
#parseDate = parseDate.strftime("%Y-%m-%d %H:%M:%S")
#starting = DateTime.strptime(params[:starting], '%Y-%m-%d') rescue @meeting_range.first 
#to_time
#puts "parseDate: #{parseDate}"
#subscription_end = Time.strptime((parseDate + 1.month.since(parseDate)), "%Y-%m-%d %H:%M:%S")
subscription_end = 1.month.since(parseDate).strftime("%Y-%m-%d %H:%M:%S")
#logger.info "subscription_end1: #{subscription_end}"
=end

=begin
total_lastday_registrations =10
total_last2day_registrations = 8
logger.info "total_lastday_registrations: #{total_lastday_registrations}"

if total_lastday_registrations
	percent_lastday = sprintf("%.2f", 100*(total_lastday_registrations - total_last2day_registrations)/total_lastday_registrations)
else
	0
end
%>

AMAZON params after delete: <%=params.inspect%>
<br>
<br>
AMAZON response body: <%=response.to_s%>
