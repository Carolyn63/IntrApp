class HipsController < ActionController::Base
  def index
    @request_subscriptionid = params[:subscriptionId]
    @request_eventCode = params[:responseEventCode]
    @request_eventString = params[:responseEventString]

    logger.info "*************************#{@request_subscriptionid }"
    logger.info "*************************#{@request_eventCode }"
    logger.info "*************************#{@request_eventString }"

    #update the event vode in calls table
    params_fields = {:event_code => @request_eventCode}
    Call.find_by_subscription_id(@request_subscriptionid).update_attributes(params_fields)
		# Mysql::Error: Unknown column 'id' in 'where clause': UPDATE `calls` SET `event_code` = 'EC10' WHERE `id` = NULL
		# if you want to use update_attribute function, you need id
    logger.info "***********Subscription ID #{@request_subscriptionid} is saved with  #{@request_eventCode}**************"

  end

end
