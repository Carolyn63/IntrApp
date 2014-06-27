require "spec_helper"

describe ApplicationRequestsController do

  describe "routes" do
    it { {:get => "/companies/1/application_requests"}.should route_to(:controller => "application_requests", :company_id => "1", :action => "index") }
    it { {:get => "/companies/1/application_requests/incoming_employee_requests"}.should route_to(:controller => "application_requests", :company_id => "1", :action => "incoming_employee_requests") }
    it { {:get => "/companies/1/application_requests/employee_requests"}.should route_to(:controller => "application_requests", :company_id => "1", :action => "employee_requests") }
    it { {:put => "/companies/1/application_requests/1/approve"}.should route_to(:controller => "application_requests", :company_id => "1", :id => "1", :action => "approve") }
    it { {:put => "/companies/1/application_requests/1/reject"}.should route_to(:controller => "application_requests", :company_id => "1", :id => "1", :action => "reject") }
    it { {:put => "/companies/1/application_requests/1/resend_employee_request"}.should route_to(:controller => "application_requests", :company_id => "1", :id => "1", :action => "resend_employee_request") }
    it { {:put => "/companies/1/application_requests/1/resend_company_request"}.should route_to(:controller => "application_requests", :company_id => "1", :id => "1", :action => "resend_company_request") }
  end

  describe 'When logged in' do
    let(:company) { Factory.create(:company) }
    let(:user) { Factory.create(:user) }
    before(:each) do
      request.env["HTTP_REFERER"] = "http://test.com"
      Company.stub(:find_by_id).and_return(company)
      controller.stub(:current_user).and_return(user)
      controller.stub(:require_user).and_return(true)
    end
    describe 'on GET #index' do
      before(:each) do
        controller.stub(:only_owner).and_return(true)
        get :index, :company_id => "1"
      end
      it { should render_template :index }
      it { should respond_with :success }
      it { should assign_to :company_application_requests }
    end
    describe 'on GET #incoming_employee_requests' do
      before(:each) do
        controller.stub(:only_owner).and_return(true)
        get :incoming_employee_requests, :company_id => "1"
      end
      it { should render_template :incoming_employee_requests }
      it { should respond_with :success }
      it { should assign_to :incoming_employee_requests }
    end
    describe 'on GET #employee_requests' do
      before(:each) do
        employee = Factory.create(:employee)
        Employee.stub(:find_by_id).and_return(employee)
        get :employee_requests, :company_id => "1"
      end
      it { should render_template :employee_requests }
      it { should respond_with :success }
      it { should assign_to :employee_application_requests }
    end
    describe "on PUT #approve" do
      before do
        controller.stub(:only_owner).and_return(true)
        employee_application = Factory.create(:employee_application)
        employee_application.stub(:approved?).and_return(false)
        employee_application.stub(:approve!).and_return(true)
        EmployeeApplication.stub(:find_by_id).and_return(employee_application)
        Company.stub(:find_by_id).and_return(company)
        put :approve, :company_id => company.id, :id => employee_application.id
      end
      it { should respond_with :redirect }
      it { should assign_to :employee_application }
    end
    describe "on PUT #reject" do
      before do
        controller.stub(:only_owner).and_return(true)
        employee_application = Factory.create(:employee_application)
        employee_application.stub(:rejected?).and_return(false)
        employee_application.stub(:reject!).and_return(true)
        EmployeeApplication.stub(:find_by_id).and_return(employee_application)
        put :reject, :company_id => company.id, :id => employee_application.id
      end
      it { should respond_with :redirect }
      it { should assign_to :employee_application }
    end
    describe "on PUT #resend_company_request" do
      before do
        controller.stub(:only_owner).and_return(true)
        companification = Factory.create(:companification)
        companification.stub(:rejected?).and_return(true)
        companification.stub(:resend!).and_return(true)
        Companification.stub(:find).and_return(companification)
        put :resend_company_request, :company_id => company.id, :id => companification.id
      end
      it { should redirect_to "http://test.com" }
      it { should respond_with :redirect }
      it { should assign_to :companification }
    end
    describe "on PUT #resend_employee_request" do
      let(:employee_application) { Factory.create(:employee_application) }
      let(:employee) { Factory.create(:employee) }
      before do
        employee_application.stub(:rejected?).and_return(true)
        employee_application.stub(:resend!).and_return(true)
        EmployeeApplication.stub(:find).and_return(employee_application)
        Employee.stub(:find_by_id).and_return(employee)
        put :resend_employee_request, :company_id => company.id, :id => employee_application.id
      end
      it { should redirect_to "http://test.com" }
      it { should respond_with :redirect }
      it { should assign_to :employee_application }
    end
  end
end
