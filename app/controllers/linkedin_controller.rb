class LinkedinController < ActionController::Base

def signin
logger.info("LinkedIn Sign in Prcess>>>>>>>>>>#{params[:member_id]}")
redirect_to root_path
end

end
