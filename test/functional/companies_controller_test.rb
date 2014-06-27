require File.dirname(__FILE__) + '/../test_helper'
require 'companies_controller'

# Re-raise errors caught by the controller.
class CompaniesController; def rescue_action(e) raise e end; end

class CompaniesControllerTest < ActionController::TestCase

  def setup
    @controller = CompaniesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/companies",           :action => :index
  should_route :get,  "/companies/1",         :action => :show, :id => 1
  should_route :get,  "/companies/new",       :action => :new
  should_route :post, "/companies",           :action => :create
  should_route :get,  "/companies/1/edit",    :action => :edit, :id => 1
  should_route :get,  "/users/1/companies",        :action => :index, :user_id => 1
  should_route :get,  "/users/1/companies/1",      :action => :show, :user_id => 1, :id => 1
  should_route :get,  "/users/1/companies/new",    :action => :new, :user_id => 1
  should_route :post, "/users/1/companies",        :action => :create, :user_id => 1
  should_route :get,  "/users/1/companies/1/edit", :action => :edit, :user_id => 1, :id => 1

  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    context "don't need have company" do
      setup do
        @user = users(:new_bens_friend)
        login_as @user
      end
      context "on GET to :index" do
        setup do
           get :index, :user_id => @user.id
        end
         should_respond_with :success
         should_assign_to :user
         should_assign_to :companies
         should_assign_to :recently_companies
         should_render_template :index
         should_not_set_the_flash
         should "show user's companies" do
           assert_equal assigns(:companies), Company.by_public_and_employers(@user).paginate(:page => 1, :order => "name ASC")
           assert_equal assigns(:recently_companies), Company.public.all(:limit => 5, :order => "created_at DESC")
         end
      end
      context "on GET to :index search action" do
        setup do
           get :index, :user_id => @user.id
        end
         should_respond_with :success
         should_assign_to :user
         should_assign_to :companies
         should_render_template :index
         should_not_set_the_flash
         should "show user's companies" do
           assert_equal assigns(:companies).size, 1
           assert_equal assigns(:companies)[0], companies(:company_001)
         end
      end
      context "on GET to :new" do
        setup do
           get :new, :user_id => @user.id
        end
         should_respond_with :success
         should_assign_to :user
         should_render_template :new
         should_not_set_the_flash
      end
      unless property(:multi_company)
        context "on GET to :new only one company should be" do
          setup do
             @user = users(:ben)
             login_as @user
             get :new, :user_id => @user.id
          end
          should_respond_with :redirect
          should_assign_to :user
          should_set_the_flash_to :error
        end
      end
      context "on POST to :create" do
        setup do
          post :create, :user_id => @user.id,
                :company => {:name => "New company", :phone => "1121111"},
                :employee => {:job_title => "test",
                              :phone => "12345678",
                              :company_email => "new_test",
                              :user_id => @user.id}
        end
         should_assign_to :user
         should_assign_to :company
         should_assign_to :employee
         should_set_the_flash_to :notice
         should_respond_with :redirect
         should "return right employee" do
           assert_equal assigns(:employee).user, @user
         end
      end
    end
    context "need have company" do
      setup do
        @user = users(:ben)
        login_as @user
        @company = @user.companies.first
      end
      context "on GET to :edit without company id" do
        setup do
           get :edit, :user_id => @user.id
        end
         should_respond_with :redirect
         should_set_the_flash_to :error
      end
      context "not owner on GET to :edit" do
        setup do
           get :edit, :user_id => 2, :id => @company.id
        end
         should_respond_with :redirect
         should_set_the_flash_to :error
      end
      context "on GET to :edit" do
        setup do
           get :edit, :user_id => @company.user_id, :id => @company.id
        end
         should_respond_with :success
         should_assign_to :user
         should_assign_to :company
         should_render_template :edit
         should_not_set_the_flash
      end
      context "on PUT to :update" do
        setup do
           put :update, :user_id => @user.id, :id => @company.id,
                :company => {:name => "new title", :phone => "1234567"},
                :employee => {:job_title => "test",
                              :phone => "12345678",
                              :company_email_name => "new_test",
                              :user_id => @user.id}
        end
         should_assign_to :user
         should_assign_to :company
         should_set_the_flash_to :notice
         should_respond_with :redirect
         should "return right employee" do
           assert_equal assigns(:employee).user, @user
         end
      end
      context "on DELETE to :destroy" do
        setup do
          delete :destroy, :id => @company.id
        end
        should_assign_to :company
        should_set_the_flash_to :notice
        should_respond_with :redirect
      end
      context "on DELETE to :destroy with OnDeego error" do
        setup do
          Company.any_instance.stubs(:destroy).returns(false)
          delete :destroy, :id => @company.id
        end
        should_assign_to :company
        should_set_the_flash_to :error
        should_respond_with :redirect
      end
      context "on GET to :show" do
        setup do
          get :show, :user_id => 1, :id => @company.id
        end
        should_assign_to :user
        should_not_set_the_flash
        should_respond_with :success
      end
      context "on GET to :show only allowed user" do
        setup do
          get :show, :user_id => 1, :id => companies(:destroy_company).id
        end
        should_assign_to :user
        should_set_the_flash_to :error
        should_respond_with :redirect
      end
      context "on GET to :profile" do
        setup do
          get :profile, :user_id => 1, :id => @company.id
        end
        should_assign_to :user
        should_not_set_the_flash
        should_respond_with :success
      end
      context "on GET to :profile only allowed user" do
        setup do
          get :profile, :user_id => 1, :id => companies(:destroy_company).id
        end
        should_assign_to :user
        should_set_the_flash_to :error
        should_respond_with :redirect
      end
    end
  end
    

  
end
