class ActivateEmployeesController < ApplicationController
  layout "signup"  
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [:edit, :update ]

  def edit
  end

  # => PUT /Activate_Employee/:Perishable_ID/Edit
  #
  # Takes an updated password and stores it. 
  def update
    # Collect the entered password
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    # Set the 'Active' attribute of the user to true
    @user.active = true
    # If we can save the user details to the database
    if @user.save
      # Store a message to show the user on the next page
      flash[:notice] = t("controllers.user_account_created")
      # Redirect the user to the index page
      redirect_to root_path
    else
      flash[:notice] = t("There was a problem with your request")
      render :action => :edit
    end
  end

  # => GET /invitation?invite_token=:id
  #
  # Handles a request using an invite code. 
  def invitation
    # Looks up an employee using the given invite code 
    @employee = Employee.find_by_invitation_token(params[:invitation_token])
    # If an employee is found 
    unless @employee.blank?
      # Store the employee's user attribute
      @user = @employee.user
      # Checks if the user is active, using the 'active' column as reference  
      if @user.active
        # Reset the employee's invite code
        @employee.reset_invitation_token!
        # Destroy the current user's session if there is a session, and the current session
        # doesn't belong to the current user. 
        current_user_session.destroy if !current_user.blank? && current_user != @user
        # Redirect to the employer
        redirect_to user_employers_path(@user)
      else
        # Generate a new perishable token for the user 
        @user.reset_perishable_token!
        # Destroy the current user session if there is a session
        current_user_session.destroy unless current_user.blank?
        redirect_to edit_password_reset_path(@user.perishable_token)
        # Redirect to /Activate_Employee/:perishableID/edit
        #redirect_to edit_activate_employee_path(@user.perishable_token)
      end
    else
      redirect_to root_path
    end
  end

  private
  def load_user_using_perishable_token
    @user = User.find_by_perishable_token(params[:id], 24.hours)
    unless @user
      flash[:error] = t("controllers.your_token_has_expired")
      redirect_to root_url
    end
  end
end
