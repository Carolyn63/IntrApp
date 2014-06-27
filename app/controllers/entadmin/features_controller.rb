class Entadmin::FeaturesController  < Entadmin::ResourcesController
    
  def index
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'features/', 'all')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    flash.now[:warning]  = t("controllers.entadmin.features.retrieve_empty") if @features.blank?
    else
    flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
    end
    @features ||= '' 
  end
end
