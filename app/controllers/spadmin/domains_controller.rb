class Spadmin::DomainsController < Spadmin::ResourcesController
  def index
    #need to move to action 'search'
    if !params[:search].blank?
      response = ippbx_search('sp', 'resource=Domain&orderBy=name&sortOrder=asc&criteria={name:'+CGI::escape(params[:search])+'}', nil)
      if response.code == '200'
      @domains = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.search.empty") if @domains.blank?
      else
      flash[:error]  = t("controllers.search.error.domains_list") + "<br />" + response.body
      end
    else
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'domain/', 'available')
      if response.code == '200'
      @domains = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.empty.domains_list") if @domains.blank?
      else
      flash[:error]  = t("controllers.get.error.domains_list") + "<br />" + response.body
      end
    end
    @domains ||= ''
  end

  def new
  end

  def create
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    else
    content_json = {"name" => params[:domain][:name]}.to_json
    response = IppbxApi.ippbx_post(session[:sp_admin], session[:sp_pass], 'sp', 'domain', content_json)
    if response.code == '200'
    flash[:notice]  = t("controllers.create.ok.domain")
    redirect_to  spadmin_domains_path
    else
    flash[:error]  = t("controllers.create.error.domain") + "<br />" + response.body
    render :action => 'new'
    end
    end
  end


  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sp_admin], session[:sp_pass], 'sp', 'domain/', params[:id])
      if response.code == '200'
      flash[:notice]  = t("controllers.delete.ok.domain")
      else
      flash[:error]  = t("controllers.delete.error.domain") + "<br />" + response.body
      end
    end
    redirect_to  spadmin_domains_path
  end

end

