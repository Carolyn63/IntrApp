  # new file app/controllers/activations_controller.rb
  class ActivationsController < ApplicationController
    before_filter :require_no_user, :only => [:new, :create]
 
    def new
      @user = User.find_using_perishable_token(params[:activation_code], 1.week) || (raise Exception)
      raise Exception if @user.active?
    end
 
    def create
      @user = User.find_by_perishable_token(params[:id])
 
      raise Exception if @user.active?
      logger.info("..........#{@user.name}")
      if @user.activate!
        @user.deliver_activation_confirmation!
        redirect_to root_url
      else
        render :action => :new
      end
    end
 end