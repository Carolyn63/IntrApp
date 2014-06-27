class Admin::UsersController < Admin::ResourcesController
  actions :index, :show, :edit, :update, :destroy
  
  sortable_attributes :created_at, :email, :login, :id, :address, :cellphone,
                      :privacy, :status, :name => 'firstname'

  def info
    @companies = resource.employers
    @friendships = resource.friendships
    @contacts = resource.contacts
  end

  def block
    if resource == current_user
      flash[:error] = "You cannot block own account"
    else
      flash[:notice] = "User blocked"
      resource.change_status(User::Status::BLOCKED)
    end
    redirect_to collection_url
  end

  def unblock
    if resource == current_user
      flash[:error] = "You cannot unblock own account"
    else
      flash[:notice] = "User unblocked"
      resource.change_status(User::Status::ACTIVE)
    end
    redirect_to collection_url
  end

  def destroy
    super do |format|
      format.html do
        unless @user.errors.empty?
          flash[:alert] = t("controllers.failed_delete_user_admin") + "#{@user.errors.on_base.blank? ? '' : @user.errors.on_base}"
        end
        redirect_to collection_url
      end
    end
  end

  protected
  def collection
    if params[:search].blank?
      @users ||= end_of_association_chain.by_status(params[:status]
                                      ).by_company_id(params[:company_id]
                                      ).by_privacy(params[:privacy]
                                      ).paginate(:page => params[:page], :order => "users." + sort_order(:default => "descending"))
    else
      #filters = {}
      #filters[:status] = params[:status] unless params[:status].blank?
      #filters[:company_id] = params[:company_id] unless params[:company_id].blank?
      #filters[:privacy] = params[:privacy] unless params[:privacy].blank?
      #@users ||= end_of_association_chain.search(params[:search], :with => filters, :page => params[:page], :order => "name ASC", :star => true)
      logger.info('22222222222222222222222222222222222222222')
      
      @users ||= end_of_association_chain.by_first_letter(params[:search]).by_status(params[:status]
                                      ).by_company_id(params[:company_id]
                                      ).by_privacy(params[:privacy]
                                      ).paginate(:page => params[:page], :order => "users." + sort_order(:default => "descending"))   
    end
  end
  
end
