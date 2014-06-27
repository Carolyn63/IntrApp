require "spec_helper"

describe Department do
  it { Factory(:department).should be_valid }

  it { should belong_to :company }
  it { should have_many(:employees).dependent(:nullify) }
  it { should have_many(:department_applications).dependent(:destroy) }
  it { should have_many(:applications).through(:department_applications) }

  describe "instance" do
    let(:department) { Factory.create(:department) }
    describe "destroy" do
      it "should destroy employee_application after destroy department applications" do
        employee = Factory.create(:employee, :department => department)
        application = Factory.create(:application)
        department_application = Factory.create(:department_application, :application => application, :department => department)
        employee.applications.should == [application]
        employee_application = employee.employee_applications.last
        expect {
          expect {
            expect {
              department.reload
              department.destroy
              department.should be_destroyed
              EmployeeApplication.find_by_id(employee_application.id).should be_nil
              DepartmentApplication.find_by_id(department_application.id).should be_nil
              Department.find_by_id(department.id).should be_nil
            }.to change { EmployeeApplication.count }.by(-1)
          }.to change { DepartmentApplication.count }.by(-1)
        }.to change { Department.count }.by(-1)
        
        employee.reload
        employee.department.should be_nil
      end
    end
  end


end
