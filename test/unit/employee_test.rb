require File.dirname(__FILE__) + '/../test_helper'

class EmployeeTest < ActiveSupport::TestCase
  context "the Employee class" do
    #should_validate_presence_of :company_email

    should_belong_to :user
    should_belong_to :company
    should_have_many :employee_applications, :dependent => :destroy

    should "return only active Employee by_contacts filter" do
      @user = users(:ben)
      assert_equal Employee.by_contacts(@user).all, [employees(:employee_002), employees(:employee_005), employees(:destroy_user_as_employee)]
    end

    should "return all Employee by_all_contacts filter" do
      @user = users(:ben)
      assert_equal Employee.by_all_contacts(@user).all, [employees(:employee_002), employees(:employee_003), employees(:employee_004), employees(:employee_005), employees(:employee_006), employees(:not_logged_employee), employees(:destroy_user_as_employee)]
    end

    should "return published Employee" do
      @user = users(:ben)
      assert !Employee.by_accepted_published_employees(@user).all.blank?
      assert_equal Employee.by_accepted_published_employees(@user).all, [employees(:employee_002)]
    end

    context "on create_employee_by_company" do
      setup do
        @company = companies(:company_001)
        @params = {:user => {
                    :email => "new_email@gmail.com", :login => "test", :firstname  => "first", :lastname => "last"},
                  :employee => {:company_id => @company.id,
                                :job_title => "Manager",
                                :phone => "12345678",
                                :company_email_name => "new_test"
                                }}
      end
      should "create new user and employee for company" do
        assert_difference 'User.count' do
          assert_difference 'Employee.count' do
            success, user = Employee.create_employee_by_company @params
            assert success
            assert user.valid?
            assert !user.active
            assert_not_nil @company.employees.find_by_user_id(user.id)
          end
        end
      end
      should "not create new user, only employee for company" do
        user = users(:user_4)
        @params[:user][:email] = user.email
        assert_no_difference 'User.count' do
          assert_difference 'Employee.count' do
            success, u = Employee.create_employee_by_company @params
            assert success
            assert_not_nil @company.employees.find_by_user_id(user.id)
            assert_not_equal user.login, @params[:user][:login]
          end
        end
      end
      should "not create new user and employee for company with exist the same employee" do
        @params[:user][:email] = users(:ben).email
        assert_no_difference 'User.count' do
          assert_no_difference 'Employee.count' do
            assert_not_nil @company.employees.find_by_user_id(users(:ben).id)
            success, user = Employee.create_employee_by_company @params
            assert !success
          end
        end
      end
      should "not create new user with not valid params" do
        @params[:user][:email] = ""
        assert_no_difference 'User.count' do
          assert_no_difference 'Employee.count' do
            success, user = Employee.create_employee_by_company @params
            assert !success
          end
        end
      end
    end
    context "destroy_employees method" do
      setup do
        @company = companies(:company_003)
        @employees_ids = [employees(:employee_006).id]
      end
      should "destroy all employees and return true" do
        assert_nil Employee.destroy_employees(@company, @employees_ids)
        assert_nil Employee.find_by_id(@employees_ids[0])
      end
      should "destroy only current company employees" do
        @company = companies(:company_001)
        assert_nil Employee.destroy_employees(@company, @employees_ids)
        assert_not_nil Employee.find_by_id(@employees_ids[0])
      end
      should "not destroy company owner employee" do
        @company = companies(:company_001)
        @employees_ids = [employees(:employee_001).id]
        assert_not_nil not_destroy_employee = Employee.destroy_employees(@company, @employees_ids)
        assert_not_nil Employee.find_by_id(not_destroy_employee.id)
        assert_not_nil not_destroy_employee.errors.on_base
      end
    end

    context "generate unique email address" do
      should "return right next unique email" do
        @arr = []
        ["new","new1", "new2", "new3", "new10", "new100", "newtest"].each do |e|
          @arr << create_employee(:company_email_name => e)
        end
        @email = "new@test.com"
        Employee.stubs(:all).returns(@arr)
        assert_equal Employee.unique_email_name(@email), "new4"
        assert_equal Employee.unique_email_name("new1@test.com"), "new11"
        assert_equal Employee.unique_email_name("new100@test.com"), "new1001"
      end
    end
  end

  context "An Instance" do
    setup do
      @employee = employees(:employee_001)
    end
    should "belongs to company" do
      assert_equal @employee.company, companies(:company_001)
    end
    should "belongs to user" do
      assert_equal @employee.user, users(:ben)
    end
    should "return right company email name" do
      @employee = employees(:employee_001)
      assert_equal @employee.company_email_name, "test"
    end
    should "should update withot update password" do
      assert @employee.update_attributes(:job_title => "new title")
    end
    should "not allow delete employee of owner company" do
      assert !@employee.destroy
      assert_not_nil @employee.errors.on_base
      assert_not_nil Employee.find_by_id(@employee.id)
    end
    should "delete user, which not logged any time, when pending employee delete" do
      @employee = employees(:not_logged_employee)
      user = @employee
      assert @employee.destroy
      assert_nil Employee.find_by_id(@employee.id)
      assert_nil User.find_by_id(user.id)
    end
    should "not delete user, which logged once, when pending employee delete" do
      @employee = employees(:employee_004)
      user = @employee
      assert @employee.destroy
      assert_nil Employee.find_by_id(@employee.id)
      assert_not_nil User.find_by_id(user.id)
    end
    should "return right user password" do
      assert_equal @employee.user.decrypted_user_password, "benrock"
      assert_equal @employee.email_password, "benrock"
    end

    context "Ondeego API" do
      setup do
        set_property(:use_ondeego, true)
      end
      teardown do
        set_property(:use_ondeego, false)
      end
      should "connect to ondeego" do
        Services::OnDeego::OauthClient.any_instance.stubs(:get_access_token).returns(OAuth::Token.new("token", "secret"))
        @employee.update_attributes(:ondeego_user_id => 0, :is_ondeego_connect => 0)
        assert @employee.ondeego_connect!(1)
        @employee.reload
        assert_equal @employee.ondeego_user_id, 1
        assert_equal @employee.is_ondeego_connect, 1
        assert_equal @employee.oauth_token, "token"
        assert_equal @employee.oauth_secret, "secret"
      end
      should "update ondeeego employee" do
        RestClient.stubs(:post).returns("<html>success</html>")
        @employee.job_title = "new job title"
        assert @employee.need_ondeego_update?
        assert @employee.save
        assert_equal @employee.job_title, "new job title"
      end
      should "not update employee and generate OnDeego error" do
        RestClient.stubs(:post).raises(RestClient::ResourceNotFound)
        @employee.job_title = "new job title"
        assert @employee.need_ondeego_update?
        assert !@employee.save
        @employee.reload
        assert_not_equal @employee.job_title, "new job title"
        assert @employee.errors.on_base, "Ondeego error: #{Services::OnDeego::Errors::Messages::TO_MESSAGE[RestClient::ResourceNotFound]}"
      end
      should "published only active request" do
        @employee = employees(:employee_002)
        @employee.update_attributes(:published_at => nil)
        assert @employee.published!
        assert !@employee.published_at.blank?
      end
      should "not published already published request" do
        @employee = employees(:employee_002)
        published_at = @employee.published_at
        assert !@employee.published!
        assert_equal @employee.published_at, published_at
      end
      should "not published not active published request" do
        @employee = employees(:employee_007)
        assert !@employee.published!
        assert @employee.published_at.blank?
      end
    end
    context "On Sogo API" do
      setup do
        @employee.update_attributes(:is_sogo_connect => 0, :status => Employee::Status::PENDING)
        set_property(:use_sogo, true)
        set_property(:use_mobile_tribe, false)
      end
      teardown do
        set_property(:use_sogo, false)
      end
      should "connect to sogo" do
        RestClient::Resource.any_instance.stubs(:post).returns("success")
        assert_equal @employee.status, Employee::Status::PENDING
        @employee.accept
        assert_equal @employee.status, Employee::Status::ACTIVE
        assert @employee.sogo_connect?
      end
      should "update sogo when user password change" do
        #RestClient::Resource.any_instance.stubs(:post).returns("success")
        #Services::Sogo::Wrapper.expects(:new)
        Services::Sogo::Wrapper.any_instance.expects(:update_user).at_least(2)
        @user = @employee.user
        assert @user.update_attributes(:password => "new password", :password_confirmation => "new password")
        @employee.reload
        assert_equal @employee.email_password, "new password"
      end
    end
    context "On MobileTribe API" do
      setup do
        set_property(:use_mobile_tribe, true)
        Employee.any_instance.stubs(:create_sogo_account).returns(true)
        @employee = employees(:employee_004)
      end
      teardown do
        set_property(:use_mobile_tribe, false)
      end
      should "call create calendar and mail for MT" do
        RestClient::Resource.any_instance.stubs(:get).returns("<answer>success</answer>")
        assert !@employee.sogo_connect?
        assert @employee.user.mobile_tribe_user?
        assert_not_equal @employee.status, Employee::Status::ACTIVE
        @employee.accept
        assert_equal @employee.status, Employee::Status::ACTIVE
        assert @employee.is_mobile_tribe_connect == 1
      end
    end

    context "reject employee" do
      setup do
        set_property(:use_mobile_tribe, true)
        set_property(:use_sogo, true)
        set_property(:use_ondeego, true)
        @employee = employees(:employee_002)
      end
      teardown do
        set_property(:use_sogo, false)
        set_property(:use_mobile_tribe, false)
        set_property(:use_ondeego, false)
      end
      should "return error when employee of company owner" do
        @employee = employees(:employee_001)
        @employee.reject
        assert !@employee.errors.empty?
        assert @employee.status, Employee::Status::ACTIVE
      end
      should "remove OnDeego, Sogo and MobileTribe relations and reject employee" do
        Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).returns(true)
        Services::Sogo::Wrapper.any_instance.expects(:delete_user).returns(true)
        Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).returns(true)
        @employee.reject
        assert @employee.errors.empty?
        assert @employee.status, Employee::Status::REJECTED
        assert @employee.is_ondeego_connect, 0
        assert @employee.is_sogo_connect, 0
        assert @employee.is_mobile_tribe_connect, 0
      end
      should "remove OnDeego, Sogo relations, except MobileTribe and doesn't reject employee" do
        Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).returns(true)
        Services::Sogo::Wrapper.any_instance.expects(:delete_user).returns(true)
        Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).raises(Services::MobileTribe::Errors::MobileTribeError)
        @employee.reject
        assert !@employee.errors.empty?
        assert @employee.status, Employee::Status::ACTIVE
        assert @employee.is_ondeego_connect, 0
        assert @employee.is_sogo_connect, 0
        assert @employee.is_mobile_tribe_connect, 1
      end
    end

    context "delete employee from connection portals" do
      setup do
        set_property(:use_mobile_tribe, true)
        set_property(:use_sogo, true)
        set_property(:use_ondeego, true)
        @employee = employees(:employee_002)
      end
      teardown do
        set_property(:use_sogo, false)
        set_property(:use_mobile_tribe, false)
        set_property(:use_ondeego, false)
      end
      should "remove OnDeego, Sogo and MobileTribe relations and delete employee" do
        assert_difference 'Audit.count' do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).returns(true)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).returns(true)
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).returns(true)
          @employee.destroy
          assert @employee.errors.empty?
          assert_nil Employee.find_by_id(@employee.id)

          audit = Audit.last
          assert_equal audit.auditable_id, @employee.id
          assert_equal audit.status, Audit::Statuses::SUCCESS
        end
      end
      should "not delete employee when exception on some portals happened" do
        assert_difference 'Audit.count' do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).returns(true)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).returns(true)
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).raises(Services::MobileTribe::Errors::MobileTribeError)
          @employee.destroy
          assert !@employee.errors.empty?
          assert_nil Employee.find_by_id(@employee.id)

          audit = Audit.last
          assert_equal audit.auditable_id, @employee.id
          assert_equal audit.status, Audit::Statuses::FAILED
        end
      end
    end
  end

  context "On create" do
    should "with right " do
      assert_difference 'Employee.count' do
        employee = create_employee
        assert_valid employee
        assert !employee.new_record?, "#{employee.errors.full_messages.to_sentence}"
      end
    end
    should "without email" do
      assert_no_difference('Employee.count') do
        employee = create_employee(:company_email_name => nil)
        assert employee.errors.on(:company_email_name)
      end
    end
    should "with wrong email" do
      assert_no_difference('Employee.count') do
        employee = create_employee(:company_email_name => "tom @test.com")
        assert employee.errors.on(:company_email_name)
      end
    end
    should "with wrong email" do
      assert_no_difference('Employee.count') do
        employee = create_employee(:company_email_name => "")
        assert employee.errors.on(:company_email_name)
      end
    end
  end

  protected

  def create_employee options = {}
    Employee.create({
        :user_id => users(:ben).id,
        :company_id => 4,
        :phone => "12345566",
        :job_title => "Manager",
        :company_email_name => "new_test"
      }.merge(options))
  end

end
