require "spec_helper"

describe Company do
  it { Factory(:company).should be_valid }

  it { should have_many :companifications }
  it { should have_many :applications }
  it { should have_many(:employee_application_requests).through(:employees) }

  describe "instance" do
    let(:company) { Factory.create(:company) }
    describe "#active_employees_per_application" do
      it "should return company active employee with application" do
        applications = 3.times.map{ Factory.create(:application) }
        employees = 2.times.map{ Factory.create(:employee, :company => company) }
        applications.each{ |a| Factory.create(:companification, :application => a, :company => company) }
        Factory.create(:employee_application, :application => applications[0], :employee => employees[0])
        Factory.create(:employee_application, :application => applications[1], :employee => employees[1], :status => EmployeeApplication::Status::PENDING)
        company.active_employees_per_application(applications[0]).should == [employees[0]]
        company.active_employees_per_application(applications[1]).should be_empty
        company.active_employees_per_application(applications[2]).should be_empty
      end
    end
    describe "#departments_per_application" do
      it "should return company departments with application" do
        applications = 3.times.map{ Factory.create(:application) }
        departments = 2.times.map{ Factory.create(:department, :company => company) }
        applications.each{ |a| Factory.create(:companification, :application => a, :company => company) }
        Factory.create(:department_application, :application => applications[0], :department => departments[0])
        Factory.create(:department_application, :application => applications[1], :department => departments[1])
        company.departments_per_application(applications[0]).should == [departments[0]]
        company.departments_per_application(applications[1]).should == [departments[1]]
        company.departments_per_application(applications[2]).should be_empty
      end
    end
    describe "#has_approved_application?" do
      let(:application){ Factory.create(:application) }
      it "should return true if application available for company" do
        Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::APPROVED)
        company.has_approved_application?(application).should be_true
      end
      it "should return false if application not available for company" do
        company.has_approved_application?(application).should be_false
        
        Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::PENDING)
        company.has_approved_application?(application).should be_false
      end
    end
    describe "#can_request_application?" do
      let(:application){ Factory.create(:application) }
      it "should return true if owner can request application" do
        company.can_request_application?(application).should be_true
      end
      it "should return false if company has request for pending application" do
        Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::PENDING)
        company.can_request_application?(application).should be_false
      end
      it "should return false if company has request for approved application" do
        Factory.create(:companification, :application => application, :company => company, :status => Companification::Status::APPROVED)
        company.can_request_application?(application).should be_false
      end
    end
  end
end
