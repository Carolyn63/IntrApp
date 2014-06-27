class FriendshipsController < ApplicationController
  before_filter :require_user
  before_filter :find_user
  before_filter :find_friendship, :only => [:accept, :reject]
  before_filter :check_friendship_fill, :only => [:accept_all, :reject_all, :resend_all, :destroy_all]

  def incoming_requests
    @incoming_requests = @user.incoming_requests.pending.paginate :page => params[:page]
  end

  def outcoming_requests
    @outcoming_requests = @user.outcoming_requests.pending.paginate :page => params[:page]
  end

  def rejected_outcoming_requests
    @rejected_outcoming_requests = @user.outcoming_requests.rejected.paginate :page => params[:page]
  end

  def accept_all
    Friendship.accept_friendships @user, params[:friendships]
    flash[:notice]  = t("controllers.friendship_accepted")
    redirect_to incoming_requests_user_friendships_path(@user)
  end

  def reject_all
    Friendship.reject_friendships @user, params[:friendships]
    flash[:notice]  = t("controllers.friendship_rejected")
    redirect_to incoming_requests_user_friendships_path(@user)
  end

  def resend_all
    Friendship.resend_friendships @user, params[:friendships]
    flash[:notice]  = t("controllers.friendship_resend")
    redirect_to rejected_outcoming_requests_user_friendships_path(@user)
  end

  def destroy_all
    Friendship.destroy_friendships @user, params[:friendships]
    flash[:notice]  = t("controllers.friendship_deleted")
    redirect_to :back
  end

  def accept
    unless @friendship.active?
      @friendship.accept
      flash[:notice]  = t("controllers.friendship_accepted")
    else
      flash[:notice]  = t("controllers.friendship_accepted_already")
    end
    redirect_to user_dashboard_index_path(current_user.id)
  end

  def reject
    unless @friendship.reject?
      @friendship.reject
      flash[:notice]  = t("controllers.friendship_rejected")
    else
      flash[:notice]  = t("controllers.friendship_rejected_already")
    end
    redirect_to user_dashboard_index_path(current_user.id)
  end

  protected

  def find_user
    @user = User.find_by_id params[:user_id]
    report_maflormed_data unless @user == current_user
  end

  def find_friendship
    @friendship = @user.incoming_requests.find_by_id(params[:id])
    report_maflormed_data(t("controllers.friendship_request_has_been_withdrawn")) if @friendship.blank?
  end

  def check_friendship_fill
    if params[:friendships].blank?
      flash[:error]  = t("controllers.select_any_friendship")
      redirect_to :back
    end
  end
end
