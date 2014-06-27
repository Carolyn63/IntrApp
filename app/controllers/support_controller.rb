class SupportController < ApplicationController
  before_filter :require_user

  def contact_us

  end

  def send_contact_us_email
    if params[:name].blank? || params[:email].blank? || params[:reason].blank? || params[:description].blank?
      flash.now[:error] = t("controllers.all_fields_required")
      render :action => :contact_us
    else
      Notifier.deliver_contact_us(params)
      flash[:notice] = t("controllers.your_question_sent")
      redirect_to root_path
    end
  end

  def mobile_tribe_description
    cookies["mt_client_link_click"] =  {"value" => "1",
                                        "path" => "/",
                                        "domain" => property(:cookies_domain)}
    render :layout => false
  end

#  def mobile_tribe_client
#
#    render :update do |page|
# #     if success
#  #    else
#  #      page["edit_company_email"].replace_html :partial => "edit_company_email"
#  #    end
#    end
##    render :layout => false
#  end

end
