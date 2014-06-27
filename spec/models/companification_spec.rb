require "spec_helper"

describe Companification do
  xit { Factory.build(:companification).should be_valid }

  it { should belong_to :application }
  it { should belong_to :company }
  xit { should validate_uniqueness_of(:application_id).scoped_to(:company_id) }


  describe 'Approved companies counter' do
    it "should increase couter when approved company has been added and decrise whan removed" do
      @application = Factory(:companification, :status => Companification::Status::APPROVED).application
      @application.reload
      @application.approved_companies_count.should eql 1
      @application.companifications.destroy_all
      @application.reload
      @application.approved_companies_count.should eql 0
    end

    it "should not increase increase couter when not approved company has been added" do
      @application = Factory(:companification, :status => Companification::Status::REJECTED).application
      @application.reload
      @application.approved_companies_count.should eql 0
      #TODO remove approved company
    end

    it "descrise couter when approved company has been reject" do
      pending "Event 'reject' cannot transition from 'approved'"
    end

  end

  describe "#destroy" do
    let(:companification) { Factory.create(:companification) }
    it {
      companification.destroy
      companification.should be_destroyed
    }
    it "should remove employee_applications and department_applications" do
      company = companification.company
      application = companification.application
      department =Factory.create(:department, :company => company)
      employee =Factory.create(:employee, :company => company)
      department_application = Factory.create(:department_application, :department => department, :application => application)
      employee_application = Factory.create(:employee_application, :application => application, :employee => employee)
      expect {
        expect {
          companification.destroy
          companification.should be_destroyed
        }.to change { EmployeeApplication.count }.by(-1)
      }.to change { DepartmentApplication.count }.by(-1)
    end
  end
end
