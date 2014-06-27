class Spadmin::RdpgsController < Spadmin::ResourcesController
  def new
  end

  def create
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    else
      #need to modify, "routingXml" => ""
      content_json = {"name" => params[:rdpgs][:name],"description" => params[:rdpgs][:description],
        "routingXml" => ""}.to_json

      response = IppbxApi.ippbx_post(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup', content_json)

      if response.code == '200'
      flash[:notice]  = t("controllers.create.ok.rdpg")
      redirect_to  spadmin_rdpgs_path
      else
      flash[:error]  = t("controllers.create.error.rdpg") + "<br />" + response.body
      render :action => 'new'
      end
    end
  end

  def index
    if !params[:search].blank?
      response = ippbx_search('sp', 'resource=RoutingDialPlanGroup&orderBy=name&sortOrder=asc&criteria={name='+CGI::escape(params[:search])+'}', nil)
      if response.code == '200'
      @rdpgs = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.search.empty") if @rdpgs.blank?
      else
      flash[:error]  = t("controllers.search.error.rdpgs_list") + "<br />" + response.body
      end
    else
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup/', 'available')
      if response.code == '200'
      @rdpgs = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.empty.rdpgs_list") if @rdpgs.blank?
      else
      flash[:error]  = t("controllers.get.error.rdpgs_list") + "<br />" + response.body
      end
    end
    @rdpgs ||= ''
  end

  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup/', params[:id])
      if response.code == '200'
      flash[:notice]  = t("controllers.delete.ok.rdpg")
      else
      flash[:error]  = t("controllers.delete.error.rdpg") + "<br />" + response.body
      end
    end
    redirect_to  spadmin_rdpgs_path
  end

  def update
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    else
      content_json = {"uid" => params[:id], "name" => params[:rdpgs][:name], "description" => params[:rdpgs][:description]}.to_json

      response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup', content_json)

      if response.code == '200'
      flash[:notice]  = t("controllers.update.ok.rdpg")
      redirect_to :action => :index
      else
      flash[:error]  = t("controllers.update.error.rdpg") + "<br />" + response.body
      redirect_to :action => :edit
      end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup/', params[:id])
    if response.code == '200'
    @response_decode = ActiveSupport::JSON.decode(response.body)
    @name = @response_decode["name"]
    @description = @response_decode["description"]
    @uid = @response_decode["uid"]
    #@routingXml = @response_decode["routingXml"]
    else
    flash[:error]  = t("controllers.get.error.rdpg") + "<br />" + response.body
    end
  end
end
