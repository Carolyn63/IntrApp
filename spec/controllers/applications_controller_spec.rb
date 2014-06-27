require "spec_helper"

describe ApplicationsController do

  describe "routes" do
    it { {:get => "/users/1/applications"}.should route_to(:controller => "applications", :user_id => "1", :action => "index") }
    it { {:get => "/users/1/applications/1"}.should route_to(:controller => "applications", :user_id => "1", :id => "1", :action => "show") }
    it { {:get => "/users/1/applications/company_catalog"}.should route_to(:controller => "applications", :user_id => "1", :action => "company_catalog") }
    it { {:get => "/users/1/applications/my_applications"}.should route_to(:controller => "applications", :user_id => "1", :action => "my_applications") }
    it { {:post => "/users/1/applications/1/assign_employees_or_departments"}.should route_to(:controller => "applications", :user_id => "1", :id => "1",
                                                                                              :action => "assign_employees_or_departments") }
    it { {:put => "/users/1/applications/1/send_request"}.should route_to(:controller => "applications", :user_id => "1", :id => "1", :action => "send_request") }
    it { {:put => "/users/1/applications/1/send_employee_request"}.should route_to(:controller => "applications", :user_id => "1", :id => "1", :action => "send_employee_request") }
  end

  describe 'When logged in' do
    before(:each) do
      request.env["HTTP_REFERER"] = "http://test.com"
      controller.stub(:require_user).and_return(true)
      controller.stub(:find_user).and_return(true)
      controller.stub(:prepare_tabs).and_return(true)
      controller.stub(:ensure_current_user_company).and_return(true)
    end
    describe 'on GET #index' do
      before(:each) do
        get :index, :user_id => "1"
      end
      it { should render_template :index }
      it { should respond_with :success }
      it { should assign_to :applications }
    end
    describe 'on GET #show' do
      before(:each) do
        @application = Factory.create(:application)
        get :show, :user_id => "1", :id => @application.id
      end
      it { should render_template :show }
      it { should respond_with :success }
      it { should assign_to :application }
    end
    describe 'on GET #company_catalog' do
      before(:each) do
        company = Factory.create(:company)
        controller.stub(:current_own_company).and_return(company)
        get :company_catalog, :user_id => "1"
      end
      xit { should render_template :company_catalog }
      xit { should respond_with :success }
      xit { should assign_to :applications }
    end
    describe 'on GET #my_applications' do
      before(:each) do
        employee = Factory.stub(:employee)
        user = Factory.stub(:user)
        User.any_instance.stub(:active_employees).and_return(Employee)
        Employee.stub(:all).and_return([employee])
        controller.stub(:current_user).and_return(user)
        get :my_applications, :user_id => "1"
      end
      it { should render_template :my_applications }
      it { should respond_with :success }
      it { should assign_to :applications }
    end
    describe 'on POST #assign_employees_or_departments' do
      let(:user) { Factory.stub(:user) }
      let(:application) { Factory.create(:application) }
      before do
        controller.stub(:current_user).and_return(user)
        controller.stub(:current_own_company).and_return(Factory.stub(:company))
      end
      context "when assign successfully" do
        before do
          application.stub(:update_attributes).and_return(true)
          Application.stub(:find_by_id).and_return(application)
          post :assign_employees_or_departments, :id => user.id, :employee_ids => ["1", "2"]
        end
        it { should redirect_to user_application_path(user, application) }
        it { should respond_with :redirect }
        it { should assign_to :application }
        it { flash[:notice].should == I18n.t("controllers.application_success_assign") }
      end
      context "when assign failed" do
        before do
          application.stub(:update_attributes).and_return(false)
          Application.stub(:find_by_id).and_return(application)
          post :assign_employees_or_departments, :id => user.id, :department_ids => ["1", "2"]
        end
        it { should redirect_to user_application_path(user, application) }
        it { flash[:error].should == I18n.t("controllers.application_assign_failed") }
      end
    end
    describe 'on PUT #send_request' do
      before do
        user = Factory.stub(:user)
        controller.stub(:current_user).and_return(user)
        company = Factory.create(:company)
        Company.stub(:find).and_return(company)
        companification = stub_model(Companification)
        companification.stub(:save).and_return(true)
        Companification.stub(:build).and_return(companification)
        application = Factory.create(:application)
        Application.stub(:find_by_id).and_return(application)
        put :send_request, :id => user.id, :company_id => "1"
      end
      it { should respond_with :redirect }
      it { should redirect_to "http://test.com" }
      it { flash[:notice].should == I18n.t("controllers.application_request_sent") }
    end
    describe 'on PUT #send_employee_request' do
      before do
        user = Factory.stub(:user)
        controller.stub(:current_user).and_return(user)
        employee = Factory.create(:employee)
        Employee.stub(:find).and_return(employee)
        employee_application = stub_model(EmployeeApplication)
        employee_application.stub(:save).and_return(true)
        EmployeeApplication.stub(:build).and_return(employee_application)
        application = Factory.create(:application)
        Application.stub(:find_by_id).and_return(application)
        put :send_employee_request, :id => user.id, :company_id => "1"
      end
      it { should respond_with :redirect }
      it { should redirect_to "http://test.com" }
      it { flash[:notice].should == I18n.t("controllers.application_request_sent") }
    end
  end
end
