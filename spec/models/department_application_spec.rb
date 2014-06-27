require 'spec_helper'

describe DepartmentApplication do
  it { should belong_to :application }
  it { should belong_to :department }

  it { should validate_presence_of :application }
  it { should validate_presence_of :department }
  xit { should validate_uniqueness_of(:department_id).scoped_to([:application_id]) }

  describe "#create" do
    let(:department_application) { Factory.build(:department_application) }
    it { department_application.should be_valid }
    it "should create employee_application for department employees" do
      department = department_application.department
      company = department.company
      employees = 2.times.map{ Factory.create(:employee, :company => company, :department => department) }
      expect {
        department_application.save.should be_true
      }.to change{ EmployeeApplication.count }.by(2)
      ea = EmployeeApplication.last
      ea.application.should == department_application.application
      employees.should include(ea.employee)
    end
    it "should approve existed pending or reject employee_application for department employees" do
      department = department_application.department
      company = department.company
      employees = 3.times.map{ Factory.create(:employee, :company => company, :department => department) }
      request = Factory.create(:employee_application, :application => department_application.application, :employee => employees[0], :status => EmployeeApplication::Status::PENDING)
      reject_request = Factory.create(:employee_application, :application => department_application.application, :employee => employees[1], :status => EmployeeApplication::Status::REJECTED)
      request.approved?.should be_false
      reject_request.approved?.should be_false

      expect {
        department_application.save.should be_true
        request.reload.approved?.should be_true
        reject_request.reload.approved?.should be_true
      }.to change{ EmployeeApplication.count }.by(1)
    end
  end


  describe "#destroy" do
    let(:department_application) { Factory.create(:department_application) }
    it {
      department_application.destroy
      department_application.should be_destroyed
    }
    it "should remove employee_application for department employees" do
      department = department_application.department
      employees = 2.times.map{ Factory.create(:employee, :company => department.company, :department => department) }
      employee_application = employees[0].employee_applications[0]
      employee_application.should_not be_nil
      employee_application.application.should == department_application.application
      department_application.reload
      expect {
        department_application.destroy
        department_application.should be_destroyed
        EmployeeApplication.find_by_id(employee_application.id).should be_nil
      }.to change{ EmployeeApplication.count }.by(-2)
    end
  end
end
