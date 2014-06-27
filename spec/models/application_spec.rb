require "spec_helper"

describe Application do
  it { Factory.build(:application).should be_valid }

  it { should validate_presence_of :name }
  it { should validate_presence_of :devices }

  it { should have_attribute :logo }
  it { should have_attribute :bin_file }

  it { should have_attribute :description }
  it { should have_attribute :price }
  it { should have_attribute :provider }
  it { should have_attribute :external_url }

  it { should have_attribute :bin_file }

  it { should have_attribute :status }
  it { should_not have_attribute :active }

  xit { should_not allow_value(-1).for(:status) }
  it { should allow_value(1).for(:status) }
  it { should allow_value(0).for(:status) }

  it { should have_many :devices }
  it { should have_many :categories }
  it { should have_many :application_types }
  it { should have_many(:employees).through(:employee_applications) }
  it { should have_many(:approved_employees).through(:employee_applications) }
  it { should have_many(:employee_applications).dependent(:destroy) }
  it { should have_many(:departments).through(:department_applications) }
  it { should have_many(:department_applications).dependent(:destroy) }

  describe '#departments_count' do
    it { should validate_presence_of :departments_count }
  end

  describe '#emploees_count' do
    it { should validate_presence_of :employees_count }
  end

  describe '#approved_emploees_count' do
    it { should validate_presence_of :approved_employees_count }
  end


  describe 'scopes' do
    subject { described_class }

    it { should respond_to :available }
    it { should respond_to :by_status }
    it { should respond_to :by_company_id }
    it { should respond_to :by_device_id }
    it { should respond_to :by_category_id }
    it { should respond_to :by_application_type_id }
    it { should respond_to :by_category_ids }
    it { should respond_to :by_device_ids }
  end

  describe "instance" do
   let(:application) { Factory.create(:application, :status => 0) }
    describe "#department_ids=" do
      let(:company) { Factory.create(:company) }
      let(:departments) { 2.times.map{ Factory.create(:department, :company => company) } }
      before{ application.assign_company = company }
      it "should destroy deparment application" do
        department_applications = departments.each{|d| Factory.create(:department_application, :department => d, :application => application) }
        expect {
          application.department_ids = [departments[1].id]
          DepartmentApplication.find_by_id(department_applications[0].id).should be_nil
        }.to change { DepartmentApplication.count }.by(-1)
      end
      it "should not remove department application request from other companies" do
        other_company = Factory.create(:company)
        department_from_other = Factory.create(:department, :company => other_company)
        request = Factory.create(:department_application, :application => application, :department => department_from_other)
        expect {
          application.department_ids = [""]
          DepartmentApplication.find_by_id(request.id).should == request
        }.to_not change { DepartmentApplication.count }
      end
    end

    describe "#company_ids=" do
      let(:companies) { 3.times.map{ Factory.create(:company) } }

      it "should approve existed pending and reject company application request" do
        request = Factory.create(:companification, :application => application, :company => companies[0], :status => Companification::Status::PENDING)
        reject_request = Factory.create(:companification, :application => application, :company => companies[1], :status => Companification::Status::REJECTED)
        request.approved?.should be_false
        reject_request.approved?.should be_false
        expect {
          application.company_ids = companies.map(&:id)
          request.reload.approved?.should be_true
          reject_request.reload.approved?.should be_true
        }.to change { Companification.count }.by(1)

        application.companifications.last.approved?.should be_true
      end

      it "should not remove pending or reject company application request when application update" do
        request = Factory.create(:companification, :application => application, :company => companies[0], :status => Companification::Status::PENDING)
        reject_request = Factory.create(:companification, :application => application, :company => companies[1], :status => Companification::Status::REJECTED)
        request.approved?.should be_false
        reject_request.approved?.should be_false
        expect {
          application.company_ids = [""]
          request.reload.pending?.should be_true
          reject_request.reload.rejected?.should be_true
        }.to_not change { Companification.count }
      end

      it "should remove company employee applications and company deparment applications when active company remove" do
        company = companies[0]
        department =Factory.create(:department, :company => company)
        employee =Factory.create(:employee, :company => company)
        department_application = Factory.create(:department_application, :department => department, :application => application)
        employee_application = Factory.create(:employee_application, :application => application, :employee => employee)
        request = Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::APPROVED)
        expect {
          expect {
            expect {
              application.company_ids = [""]
            }.to change { EmployeeApplication.count }.by(-1)
          }.to change { DepartmentApplication.count }.by(-1)
        }.to change { Companification.count }.by(-1)
      end
    end

    describe "#employee_ids=" do
      let(:company) { Factory.create(:company) }
      let(:employees) { 3.times.map{ Factory.create(:employee, :company => company) } }
      before{ application.assign_company = company }

      it "should approve existed pending and reject employee application request" do
        request = Factory.create(:employee_application, :application => application, :employee => employees[0], :status => EmployeeApplication::Status::PENDING)
        reject_request = Factory.create(:employee_application, :application => application, :employee => employees[1], :status => EmployeeApplication::Status::REJECTED)
        request.approved?.should be_false
        reject_request.approved?.should be_false
        expect {
          application.employee_ids = employees.map(&:id)
          request.reload.approved?.should be_true
          reject_request.reload.approved?.should be_true
        }.to change { EmployeeApplication.count }.by(1)
        application.employee_applications.last.approved?.should be_true
      end

      it "should not remove pending or reject employee application request when application update" do
        request = Factory.create(:employee_application, :application => application, :employee => employees[0], :status => EmployeeApplication::Status::PENDING)
        reject_request = Factory.create(:employee_application, :application => application, :employee => employees[1], :status => EmployeeApplication::Status::REJECTED)
        request.approved?.should be_false
        reject_request.approved?.should be_false
        expect {
          application.employee_ids = [""]
          request.reload.pending?.should be_true
          reject_request.reload.rejected?.should be_true
        }.to_not change { EmployeeApplication.count }
      end

      it "should not remove employee application request from other companies" do
        other_company = Factory.create(:company)
        employee_from_other = Factory.create(:employee, :company => other_company)
        request = Factory.create(:employee_application, :application => application, :employee => employee_from_other, :status => EmployeeApplication::Status::APPROVED)
        expect {
          application.employee_ids = [""]
          EmployeeApplication.find_by_id(request.id).should == request
        }.to_not change { EmployeeApplication.count }
      end

      it "should remove employee applications when active employee remove" do
        employee =Factory.create(:employee, :company => company)
        employee_application = Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::APPROVED)
        expect {
          application.employee_ids = [""]
        }.to change { EmployeeApplication.count }.by(-1)
      end

      it "should call destroy_all for delete employee application" do
        employee =Factory.create(:employee, :company => company)
        employee_application = Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::APPROVED)
        EmployeeApplication.should_receive(:destroy_all)#.with(:employee_id => employee.id, :application_id => application.id)
        application.employee_ids = [""]
      end
    end

    describe "#available_for?" do
      context "by company" do
        let(:company) { Factory.create(:company) }
        it "should return true if company has approved applicaiton" do
          companification = Factory.create(:companification, :application => application, :company => company)
          application.available_for?(company).should be_true
        end
        it "should return false if company has not approved applicaiton" do
          application.available_for?(company).should be_false

          companification = Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::PENDING)
          application.available_for?(company).should be_false
        end
      end

      context "by employee" do
        let(:employee) { Factory.create(:employee) }
        it "should return true if employee has approved applicaiton" do
          employee_application = Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::APPROVED)
          application.available_for?(nil, employee).should be_true
        end

        it "should return false if employee has not approved applicaiton" do
          application.available_for?(nil, employee).should be_false

          employee_application = Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::PENDING)
          application.available_for?(nil, employee).should be_false
        end
      end

      context "when all blank" do
        it "should be false" do
          application.available_for?(nil, nil).should be_false
        end
      end
    end
    describe "#request_for" do
      context "by company" do
        let(:company) { Factory.create(:company) }
        it "should return companificaiton request if company has request for applicaiton" do
          companification = Factory.create(:companification, :application => application, :company => company)
          application.request_for(company).should == companification
        end
        it "should return nil if company has not request for applicaiton" do
          application.request_for(company).should be_nil
        end
      end
      context "by employee" do
        let(:employee) { Factory.create(:employee) }
        it "should return employee_application if employee has request for applicaiton" do
          employee_application = Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::APPROVED)
          application.request_for(nil, employee).should == employee_application
        end
        it "should return nil if employee has not request applicaiton" do
          application.request_for(nil, employee).should be_nil
        end
      end
      context "when all blank" do
        it "should be nil" do
          application.request_for(nil, nil).should be_nil
        end
      end
    end
  end

  describe "class" do
    describe "#search_or_filter_applications" do
      let(:user) { Factory.create(:user) }
      let(:params) { {:page => "1"} }

      context "without search" do
        let(:applications) { 3.times.map{ Factory.create(:application, :status => 0) } }

        it "should return all available applications" do
          available_applications = Factory.create(:application, :status => 0)
          unavailable_applications = Factory.create(:application, :status => 1)
          result = Application.search_or_filter_applications(user, params)
          result.should include(available_applications)
          result.should_not include(unavailable_applications)
        end

        it "should filter by categories" do
          categories = 3.times.map{ Factory.create(:category) }
          Factory.create(:categorization, :application => applications[0], :category => categories[0])
          Factory.create(:categorization, :application => applications[0], :category => categories[1])
          Factory.create(:categorization, :application => applications[1], :category => categories[1])
          Factory.create(:categorization, :application => applications[2], :category => categories[2])

          result = Application.search_or_filter_applications(user, params.merge(:categories_in => [categories[0], categories[1]]))
          result.should have(2).applications
          result.should include(applications[0])
          result.should include(applications[1])
          result.should_not include(applications[2])
        end

        it "should filter by device" do
          devices = 3.times.map{ Factory.create(:device) }
          Factory.create(:devicefication, :application => applications[0], :device => devices[0])
          Factory.create(:devicefication, :application => applications[0], :device => devices[1])
          Factory.create(:devicefication, :application => applications[1], :device => devices[1])
          Factory.create(:devicefication, :application => applications[2], :device => devices[2])

          result = Application.search_or_filter_applications(user, params.merge(:devices_in => [devices[0], devices[1]]))
          result.should have(2).applications
          result.should include(applications[0])
          result.should include(applications[1])
          result.should_not include(applications[2])
        end

        it "should filter by type" do
          types = 3.times.map{ Factory.create(:application_type) }
          Factory.create(:typization, :application => applications[0], :application_type => types[0])
          Factory.create(:typization, :application => applications[0], :application_type => types[1])
          Factory.create(:typization, :application => applications[1], :application_type => types[1])
          Factory.create(:typization, :application => applications[2], :application_type => types[2])

          result = Application.search_or_filter_applications(user, params.merge(:application_type_id => types[1]))
          result.should have(2).applications
          result.should include(applications[0])
          result.should include(applications[1])
          result.should_not include(applications[2])
        end

        it "should filter by company id with approved request" do
          pending_application = Factory.create(:application, :status => 0)
          companies = 2.times.map{ Factory.create(:company) }
          Factory.create(:companification, :application => applications[0], :company => companies[0], :status => Companification::Status::APPROVED)
          Factory.create(:companification, :application => pending_application, :company => companies[0], :status => Companification::Status::PENDING)
          Factory.create(:companification, :application => applications[1], :company => companies[1])

          result = Application.search_or_filter_applications(user, params.merge(:company_id => companies[0]))
          result.should have(1).applications
          result.should include(applications[0])
          result.should_not include(applications[1])
          result.should_not include(pending_application)
        end

        it "should filter by employee with approved request" do
          pending_application = Factory.create(:application, :status => 0)
          employees = 3.times.map{ Factory.create(:employee) }
          Factory.create(:employee_application, :application => applications[0], :employee => employees[0], :status => Companification::Status::APPROVED)
          Factory.create(:employee_application, :application => applications[0], :employee => employees[1])
          Factory.create(:employee_application, :application => applications[1], :employee => employees[1])
          Factory.create(:employee_application, :application => applications[2], :employee => employees[2])
          Factory.create(:employee_application, :application => pending_application, :employee => employees[0], :status => Companification::Status::PENDING)

          result = Application.search_or_filter_applications(user, params.merge(:employees_in => [employees[0], employees[1]]))
          result.should have(2).applications
          result.should include(applications[0])
          result.should include(applications[1])
          result.should_not include(applications[2])
          result.should_not include(pending_application)
        end

        it "should filter by department" do
          departments = 3.times.map{ Factory.create(:department) }
          Factory.create(:department_application, :application => applications[0], :department => departments[0])
          Factory.create(:department_application, :application => applications[0], :department => departments[1])
          Factory.create(:department_application, :application => applications[1], :department => departments[1])
          Factory.create(:department_application, :application => applications[2], :department => departments[2])

          result = Application.search_or_filter_applications(user, params.merge(:departments_in => [departments[0], departments[1]]))
          result.should have(2).applications
          result.should include(applications[0])
          result.should include(applications[1])
          result.should_not include(applications[2])
        end
      end

      context "with search" do
        xit "should call sphinx search with needed filters and return available applications" do
          available_application = Factory.create(:application, :status => 0)
          params.merge!(:search => "app", :company_id => "1", :application_type_id => "1", :categories_in => ["1", "2"],
                        :employees_in => ["1", "2"], :devices_in => ["1", "2"], :departments_in => ["1", "2"])
          Application.should_receive(:search).with("app",
                      {:with => {:application_type_id => "1", :status => Application::Status::ACTIVE, :device_id => ["1","2"], :employee_id => ["1", "2"],
                                 :department_id => ["1","2"], :company_id => "1", :company_status => Companification::Status::APPROVED.to_crc32,
                                 :employee_status => EmployeeApplication::Status::APPROVED.to_crc32, :category_id => ["1", "2"]},
                      :page => "1", :order => "name ASC", :star => true}).and_return([available_application])
          result = Application.search_or_filter_applications(user, params)
          result.should include(available_application)
        end
      end
    end
  end
end
