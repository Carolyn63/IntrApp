class Spadmin::FeaturesController < Spadmin::ResourcesController

  def index
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'features/', 'all')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
    else
    flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
    end
    @features ||= ''
  end
end
