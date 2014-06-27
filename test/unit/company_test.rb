require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < ActiveSupport::TestCase
   context "the Company class" do
    should_validate_presence_of :name, :privacy, :user_id

#    should_validate_length_of :phone, :in => 7..25
#    should_validate_length_of :industry, :in => 1..50, :allow_blank => nil
#    should_validate_length_of :address, :in => 1..50, ::allow_blank => nil
#    should_validate_length_of :city, :in => 1..50, ::allow_blank => nil
#    should_allow_values_for :phone, "1234567"
#    should validate_exclusion_of :phone, :in => ["123456", "1234567a", "12345678901234567890123456"]

    should_belong_to :admin

  end

  context "An Instance" do
    setup do
      @company = companies(:company_001)
    end
    should "return employee " do
      assert_equal @company.employee(users(:ben)), employees(:employee_001)
    end
    should "has admin_employee " do
      assert_equal @company.admin_employee, employees(:employee_001)
    end
    should "has active_user_employees " do
      assert_not_nil @company.active_user_employees
      assert_equal @company.active_user_employees[0], employees(:employee_002).user
    end
    should "has active_employees " do
      assert_not_nil @company.active_employees
      assert_equal @company.active_employees[0], employees(:employee_001)
    end
    should "return active and pendong" do
      assert !Company.active_and_pending_employers.all.blank?
      assert Company.active_and_pending_employers.size, 3
    end
    should "return public and private employers" do
      companies = Company.by_public_and_employers(users(:user_4)).all
      assert !companies.blank?
      assert companies.size, 3
    end
    context "search and filters" do
      setup do
        @user = users(:ben)
        @params = {:sort_by => "name",
                   :alphabet => @company.name.to_s.first.underscore,
                   :search => @company.name,
                   :search_by => "name"}
      end
      should "return all companies" do
        assert_equal Company.search_or_filter_companies(@user, {}), [companies(:company_001), companies(:company_003)]
      end
      should "return filters companies by first letter" do
        assert_equal Company.search_or_filter_companies(@user, @params.merge(:search => "")), [companies(:company_001)]
      end
      should "search companies by name" do
        Company.stubs(:search).returns(@company)
        Company.stubs(:sphinx_public_and_employers).returns(Company)
        assert_equal Company.search_or_filter_companies(@user, @params), @company
      end
    end
    context "OnDeego API" do
      setup do
        set_property(:use_ondeego, true)
      end
      teardown do
        set_property(:use_ondeego, false)
      end
      should "connect to ondeego" do
        @company.update_attributes(:ondeego_company_id => 0, :is_ondeego_connect => 0)
        assert @company.ondeego_connect!(1)
        @company.reload
        assert_equal @company.ondeego_company_id, 1
        assert_equal @company.is_ondeego_connect, 1
      end
       should "call ondeego update api only when need" do
         @company.name = "change name"
         assert !@company.need_ondeego_update?
         @company.logo = File.new(Rails.root + "public/images/big_box.png")
         assert @company.need_ondeego_update?
       end
    end
    context "destroy company" do
      setup do
        set_property(:use_mobile_tribe, true)
        set_property(:use_sogo, true)
        set_property(:use_ondeego, true)
        @employees = @company.employees
        assert !@employees.blank?
        @employee = @employees[0]
        assert @employee.ondeego_connect?
        assert @employee.sogo_connect?
        assert @employee.mobile_tribe_user?
      end
      teardown do
        set_property(:use_sogo, false)
        set_property(:use_mobile_tribe, false)
        set_property(:use_ondeego, false)
      end
      should "remove company with all employees and their portals connections" do
        assert_difference 'Audit.count', 4 do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_company).returns(true)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).at_least(2)
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).at_least(2)
          Employee.any_instance.expects(:delete_not_logged_user).at_least(3)
          Employee.any_instance.expects(:check_admin).never
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).never

          @company.destroy
          assert @company.errors.empty?
          assert_nil Company.find_by_id(@company.id)
          @employees.each do |e|
            assert_nil Employee.find_by_id(e.id)
          end

          audit = Audit.last
          assert_equal audit.auditable_id, @company.id
          assert_equal audit.status, Audit::Statuses::SUCCESS
          assert_equal audit.associations_audits.size, @employees.size
          assert_equal audit.associations_audits[0].auditable_id, @employees[0].id
          assert_equal audit.associations_audits[0].status, Audit::Statuses::SUCCESS
        end
      end
      should "don't remove company when employee delete error happened" do
        assert_difference 'Audit.count', 4 do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_company).returns(true)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).at_least(2)
          Employee.any_instance.expects(:delete_not_logged_user).at_least(3)
          Employee.any_instance.expects(:check_admin).never
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).at_least(3).raises(Services::MobileTribe::Errors::MobileTribeError)
#          #Call after delete_employees
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).never

          @company.destroy
          assert !@company.errors.empty?
          assert_nil Company.find_by_id(@company.id)
          @employees.each do |e|
            assert_nil Employee.find_by_id(e.id)
          end

          audit = Audit.last
          assert_equal audit.auditable_id, @company.id
          assert_equal audit.status, Audit::Statuses::FAILED
          assert_equal audit.associations_audits.size, @employees.size
          assert_equal audit.associations_audits[0].auditable_id, @employees[0].id
          assert_equal audit.associations_audits[0].status, Audit::Statuses::FAILED
        end
      end
    end
  end

  context "On create" do
    should "with right " do
      assert_difference 'Company.count' do
        company = create_company
        assert_valid company
        assert !company.new_record?, "#{company.errors.full_messages.to_sentence}"
      end
    end
    should "without name" do
      assert_no_difference('Company.count') do
        company = create_company(:name => nil)
        assert company.errors.on(:name)
      end
    end
  end

  protected

  def create_company options = {}
    Company.create({
        :user_id => users(:ben).id,
        :name => "Apple",
        :address => "USA",
        :city => "New Your",
        :phone => "55566183555",
        :company_type => "Parther",
        :privacy => Company::Privacy::PUBLIC,
        :industry => "IT",
        :size => "1",
        :description => "blabblabblabblab",
        :team => "Ben",
        :country_phone_code => "+1"
      }.merge(options))
  end

end

