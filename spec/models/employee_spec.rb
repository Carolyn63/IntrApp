require "spec_helper"

describe Employee do
  it { Factory(:employee).should be_valid }

  it { should have_many(:employee_applications).dependent(:destroy) }
  it { should have_many(:applications).through(:employee_applications) }
  it { should have_many(:employee_devices).dependent(:destroy) }
  it { should have_many(:devices).through(:employee_devices) }

  describe "update" do
    let(:department) { Factory.create(:department) }
    let(:employee) { Factory.create(:employee, :department => department) }
    describe "update department" do
      it "should call unassign_department_application_from_employee for destroy employee_applications for old department application" do
        new_department = Factory.create(:department)
        Department.should_receive(:find_by_id).with(nil).and_return(nil)
        Department.should_receive(:find_by_id).with(department.id).and_return(department)
        employee.should_receive(:unassign_department_application_from_employee).with(department)
        employee.update_attributes(:department => new_department)
      end
      it "should call assign_department_application_to_employee for create employee_applications for new department application" do
        new_department = Factory.create(:department)
        employee.should_receive(:assign_department_application_to_employee)
        employee.update_attributes(:department => new_department)
      end
    end
  end

  describe "scopes" do
    describe "#by_contacts" do
      it "should return only active contacts from active employers" do
        user = Factory.create(:user)
        active_company = Factory.create(:company)
        rejected_company = Factory.create(:company)
        active_employee = Factory.create(:employee, :user => user, :status => 'active', :company => active_company)
        rejected_employee = Factory.create(:employee, :user => user, :status => 'rejected', :company => rejected_company)

        active_coworker = Factory.create(:employee, :status => 'active', :company => active_company)
        rejected_coworker = Factory.create(:employee, :status => 'rejected', :company => active_company)
        active_not_coworker = Factory.create(:employee, :company => rejected_company)
        
        Employee.by_contacts(user).should == [active_coworker]
      end
    end
  end

  describe "instance" do
    let(:department) { Factory.create(:department) }
    let(:employee) { Factory.create(:employee, :department => department) }
    describe "#accept" do
      it "should create employee with service, connect to sogo and assign application" do
        employee.should_receive(:create_employee_with_services)
        employee.should_receive(:sogo_connect!).and_return(true)
        employee.should_receive(:activate!).and_return(true)
        employee.should_receive(:assign_department_application_to_employee).and_return(true)
        employee.accept
      end
    end
    describe "#reject" do
      it "should delete employee from service, disconnect from sogo and unassign application" do
        employee.should_receive(:delete_mobile_tribe_calendar_and_mail).and_return(true)
        employee.should_receive(:delete_sogo_account).and_return(true)
        employee.should_receive(:reject!).and_return(true)
        employee.should_receive(:unassign_department_application_from_employee).and_return(true)
        employee.reject
      end
    end
    describe "#assign_department_application_to_employee" do
      it "should assign department applications to employee" do
        application = Factory.create(:application)
        Factory.create(:department_application, :application => application, :department => department)
        expect {
          employee.send(:assign_department_application_to_employee)
          employee.employee_applications.last.application.should == application
        }.to change { EmployeeApplication.count }.by(1)
      end
    end
    describe "#unassign_department_application_from_employee" do
      it "should unassign department applications from employee" do
        application = Factory.create(:application)
        Factory.create(:department_application, :application => application, :department => department)
        another_application = Factory.create(:employee_application, :employee => employee)
        expect {
          employee.send(:unassign_department_application_from_employee, department)
          employee.employee_applications.should include(another_application)
        }.to change { EmployeeApplication.count }.by(-1)
      end
    end
    describe "#can_request_application?" do
      let(:application){ Factory.create(:application) }
      it "should return true if employee can request application" do
        employee.can_request_application?(application).should be_true
      end
      it "should return false if employee has request for pending application" do
        Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::PENDING)
        employee.can_request_application?(application).should be_false
      end
      it "should return false if employee has request for approved application" do
        Factory.create(:employee_application, :application => application, :employee => employee, :status => EmployeeApplication::Status::APPROVED)
        employee.can_request_application?(application).should be_false
      end
    end
  end
end
