require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

  context "the User class" do
    should_validate_presence_of :firstname, :lastname

    #should_validate_length_of :firstname, :lastname, :in => 1..80

    should_have_many :companies
    should_have_many :employees
    should_have_many :friendships, :dependent => :destroy
    should_have_many :friends_friendships, :dependent => :destroy
    should_have_many :friends
    should_have_many :incoming_requests
    should_have_many :outcoming_requests

  end

  context "An Instance" do
    setup do
      @user = users( :ben )
    end
    should "has many own companies" do
      assert_not_nil @user.companies
      assert_equal @user.companies.size, 2
    end
    should "be employees for different companies" do
      assert_not_nil @user.employees
      assert_equal @user.employees.size, 3
    end
    should "has different employers(companies)" do
      assert_not_nil @user.employers
      assert_equal @user.employers.size, 3
    end
    should "has different employers without own companies" do
      assert !@user.employers.without_own_companies(@user.id).all.blank?
      assert_equal @user.employers.without_own_companies(@user.id).all.size, 1
    end
    should "return active and pending employers" do
      assert !@user.employers.active_and_pending_employers.all.blank?
      assert_equal @user.employers.active_and_pending_employers.all.size, 3
    end
    should "return contacts" do
      assert !@user.contacts.blank?
      assert_equal @user.contacts, [employees(:employee_002), employees(:employee_005), employees(:destroy_user_as_employee)]
    end
    should "return public_and_coworkers" do
      users = User.public_and_coworkers(@user).all
      assert !users.blank?
      assert_equal users.size, 3
      assert_equal users, [users(:frai), users(:user_3), users(:destroy_user)]
    end
    should "return private_coworkers" do
      users = User.private_coworkers(@user).all
      assert !users.blank?
      assert_equal users.size, 1
      assert_equal users, [users(:destroy_user)]
    end
    should "return private_not_coworkers_users" do
      users = @user.private_not_coworkers_users
      assert !users.blank?
      assert_equal users.size, 3
      assert_equal users, [users(:user_4), users(:new_bens_friend), users(:user_without_password)]
    end
    should "return true if user can view user profile" do
      assert @user.can_view_user_profile?(users(:destroy_user))
      assert @user.can_view_user_profile?(users(:user_3))
    end
    should "return false if user can't view user profile" do
      assert !@user.can_view_user_profile?(users(:user_4))
    end
    should "return true if user can view company profile" do
      assert @user.can_view_company_profile?(companies(:company_003))
      companies(:destroy_company).update_attributes(:privacy => Company::Privacy::PUBLIC)
      assert @user.can_view_company_profile?(companies(:destroy_company))
    end
    should "return false if user can't view company profile" do
      assert !@user.can_view_company_profile?(companies(:destroy_company))
    end
    should "has mobile tribe user" do
      assert @user.mobile_tribe_user?
    end
    should "be owner of companies" do
      assert @user.owner_companies?
    end
    should "be not owner of companies" do
      assert @user.companies.destroy_all
      assert !@user.owner_companies?
    end
    should "top_company return own company" do
      assert_equal @user.top_company, companies(:company_001)
    end
    should "top_company return employer" do
      @user = users(:user_3)
      assert @user.companies.blank?
      assert_equal @user.top_company, companies(:company_001)
    end
    should "top_company return nil" do
      employees(:employee_006).destroy
      employees(:employee_of_destroy_company).destroy
      @user = users(:user_without_password)
      assert @user.companies.blank?
      assert @user.employers.blank?
      assert_nil @user.top_company
    end
    should "return right mobile_tribe parameters" do
      assert_equal @user.mobile_tribe_login, "ben"
      assert_equal @user.mobile_tribe_password, "benrock"
    end
    should "return true if user may be employee" do
      assert @user.may_be_coworker?(users(:destroy_user))
    end
    should "return true if user rejected prev request and may be employee" do
      assert @user.may_be_coworker?(users(:frai))
    end
    should "return false if user don't have company and can't be employee" do
      assert !users(:user_without_password).may_be_coworker?(users(:frai))
    end
    should "return false if employee already has active relation and can't be employee" do
      assert !@user.may_be_coworker?(users(:user_3))
    end
    should "delete rejected employee of user" do
      assert_difference 'Employee.count', -1 do
        users(:frai).delete_exist_rejected_employee_of_user(users(:user_without_password))
      end
    end
    should "not delete active employee of user" do
      assert_no_difference 'Employee.count' do
        @user.delete_exist_rejected_employee_of_user(users(:user_3))
      end
    end

    context "search and filters" do
      setup do
        @user = users(:ben)
        @params = {:sort_by => "firstname",
                   :alphabet => users(:frai).firstname.to_s.first.underscore,
                   :search => @user.firstname,
                   :search_by => "firstname"}
      end
      should "return all users" do
        assert_equal User.search_or_filter_users(@user, {}), User.public_and_coworkers_with_self(@user).all(:order => "firstname ASC")
      end
      should "return filters users by first letter" do
        assert_equal User.search_or_filter_users(@user, @params.merge(:search => "")), [users(:frai), users(:user_3)]
      end
      should "search users by name" do
        User.stubs(:search).returns(@user)
        User.stubs(:sphinx_public_and_coworkers).returns(User)
        assert_equal User.search_or_filter_users(nil, @params), @user
      end
    end

    context "on friends" do
      should "return friendships" do
        assert !@user.friendships.blank?
        assert_equal @user.friendships, Friendship.find_all_by_user_id(@user.id)
      end
      should "return friends_friendships" do
        assert !@user.friends_friendships.blank?
        assert_equal @user.friends_friendships, Friendship.find_all_by_friend_id(@user.id)
      end
      should "return friends" do
        assert !@user.friends.blank?
        assert_equal @user.friends.size, 1
        assert_equal @user.friends[0], users(:frai)
      end
      should "return incoming_requests" do
        @user = users(:frai)
        assert !@user.incoming_requests.blank?
        assert_equal @user.incoming_requests.size,  1
        assert_equal @user.incoming_requests[0], friendships(:ben_with_frai)
      end
      should "return outcoming_requests" do
        assert !@user.outcoming_requests.blank?
        assert_equal @user.outcoming_requests.size, 1
        assert_equal @user.outcoming_requests, [friendships(:frai_with_ben)]
      end
      should "return published active outcoming_requests" do
        assert !@user.outcoming_requests.published.blank?
        assert_equal @user.outcoming_requests.published.size, 1
        assert_equal @user.outcoming_requests.published, [friendships(:frai_with_ben)]
        assert !@user.outcoming_requests.published.blank?
      end
      should "don't have published active outcoming_requests" do
        @user = users(:frai)
        assert @user.outcoming_requests.published.blank?
      end
      should "return accepted published contacts for admin" do
        @user = users(:ben)
        assert_equal @user.accepted_published_contacts, [employees(:employee_002)]
      end
      should "return empty array for not admin" do
        @user = users(:user_3)
        assert_equal @user.accepted_published_contacts, []
      end
      should "return true for incoming_friend_request_from?" do
        assert @user.incoming_friend_request_from?(users(:new_bens_friend))
      end
    end

    context "OnDeego API" do
      setup do
        set_property(:use_ondeego, true)
      end
      teardown do
        set_property(:use_ondeego, false)
      end
      should "update all ondeego employees" do
        Services::OnDeego::OauthClient.any_instance.expects(:update_employee).at_least(1).returns(true)
        @user.firstname = "new firstname"
        assert @user.save
        assert_equal @user.firstname, "new firstname"
      end
      should "not update ondeego employees and return OnDeego error" do
        #Services::OnDeego::OauthClient.any_instance.expects(:update_employee).at_least(1).returns(true)
        RestClient.stubs(:post).raises(RestClient::ResourceNotFound)
        @user.firstname = "new firstname"
        assert !@user.save
        @user.reload
        assert_not_equal @user.firstname, "new firstname"
        assert @user.errors.on_base, "Ondeego error: #{Services::OnDeego::Errors::Messages::TO_MESSAGE[RestClient::ResourceNotFound]}"
      end
      should "call OnDeego Employee update API only if needed fields changed" do
        Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).never
        @user.phone = "123-3454-5"
        assert @user.save
        assert_equal @user.phone, "123-3454-5"
      end
    end

    context "MobileTribe API" do
      setup do
        set_property(:use_mobile_tribe, true)
      end
      teardown do
        set_property(:use_mobile_tribe, false)
      end
      context "Create user" do
        setup do
          @user = User.new(user_options)
          @user.mobile_tribe_create = true
        end
        should "create eBento user and MobileTribe user" do
          assert_difference 'User.count' do
            RestClient::Resource.any_instance.stubs(:get).returns("<mt_response><resultCode>0</resultCode><resultText>OK</resultText></mt_response>")
            assert !@user.mobile_tribe_user?
            assert @user.save
            assert_valid @user
            assert @user.mobile_tribe_user?
            assert_equal @user.mobile_tribe_login, "test user"
          end
        end
        should "not create eBento user, because MobileTribe return error" do
          assert_no_difference 'User.count' do
            RestClient::Resource.any_instance.stubs(:get).returns("<mt_response><resultCode>5000</resultCode><resultText>error</resultText></mt_response>")
            assert !@user.mobile_tribe_user?
            @user.save
            assert @user.new_record?
            assert @user.errors.on(:base)
          end
        end
      end
      context "Update user" do
        setup do
          @user = users(:ben)
          assert @user.mobile_tribe_user?
        end
        should "update eBento user and MobileTribe user" do
          RestClient::Resource.any_instance.stubs(:get).returns("<mt_response><resultCode>0</resultCode><resultText>OK</resultText></mt_response>")
          @user.update_attributes(:firstname => "new name")
          assert_equal @user.firstname, "new name"
        end
        should "update eBento user and MobileTribe user when password change" do
          set_property(:use_mobile_tribe, false)
          #RestClient::Resource.any_instance.stubs(:get).returns("<mt_response><resultCode>0</resultCode><resultText>OK</resultText></mt_response>")
#          Services::MobileTribe::Connector.any_instance.expects(:update_user)
#          Services::MobileTribe::Connector.any_instance.expects(:change_user_password)
         # User.expects(:update_mobile_tribe_user)
          @user.update_attributes(:password => "new password", :password_confirmation => "new password")
          assert_equal User.find(1).decrypted_user_password, "new password"
        end
#        should "not update eBento user, because MobileTribe return error" do
#          RestClient::Resource.any_instance.stubs(:get).returns("<mt_response><resultCode>5000</resultCode><resultText>error</resultText></mt_response>")
#          assert @user.mobile_tribe_user?
#          assert !@user.update_attributes(:lastname => "new last", :firstname => "new first")
#          @user.reload
#          assert @user.errors.on(:base)
#          assert_not_equal @user.lastname, "new last"
#        end
      end
    end
    context "On Sogo API" do
      setup do
        set_property(:use_sogo, true)
        set_property(:use_mobile_tribe, false)
      end
      teardown do
        set_property(:use_sogo, false)
      end
      should "update employees sogo account" do
        @user.expects(:update_sogo_accounts)
        Services::Sogo::Wrapper.stubs(:update_user).returns(true)
        @user.firstname = "new firstname"
        assert @user.save
      end
    end
    context "destroy user" do
      setup do
        set_property(:use_mobile_tribe, true)
        set_property(:use_sogo, true)
        set_property(:use_ondeego, true)
        
        @user = users(:destroy_user)
        @companies = @user.companies
        assert_equal @companies.size, 1
        @employees = @user.employees
        assert_equal @employees.size, 2
        @relate_company_contacts = [employees(:employee_of_destroy_company)]
        assert_equal @relate_company_contacts.size, 1
      end
      teardown do
        set_property(:use_sogo, false)
        set_property(:use_mobile_tribe, false)
        set_property(:use_ondeego, false)
      end
      should "remove user with all companies and employees and their portals connections" do
        assert_difference 'Audit.count', 5 do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_company).at_least(1)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).at_least(3)
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).at_least(3)
          Employee.any_instance.expects(:delete_not_logged_user).at_least(3)
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).at_least(1)
          Employee.any_instance.expects(:check_admin).at_least(1)
          Services::MobileTribe::Connector.any_instance.expects(:remove_association).at_least(1)

          @user.destroy
          assert @user.errors.empty?
          assert_nil User.find_by_id(@user.id)
          @companies.each { |c| assert_nil Company.find_by_id(c.id) }
          @employees.each { |e| assert_nil Employee.find_by_id(e.id) }
          @relate_company_contacts.each { |e| assert_nil Employee.find_by_id(e.id) }

          audit = Audit.last
          assert_equal audit.auditable_id, @user.id
          assert_equal audit.status, Audit::Statuses::SUCCESS
          assert_equal audit.associations_audits.size, @companies.size
          company_audit = @companies[0]
          assert_equal company_audit.id, @companies[0].id
          assert_equal company_audit.audit.status, Audit::Statuses::SUCCESS
          assert_equal company_audit.audit.associations_audits.size, 2
          assert_equal company_audit.audit.associations_audits[0].status, Audit::Statuses::SUCCESS
        end
      end
      should "don't remove user when employee remove portals connections error happened" do
        assert_difference 'Audit.count', 5 do
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).at_least(3).raises(Services::MobileTribe::Errors::MobileTribeError)
          Services::OnDeego::OauthClient.any_instance.expects(:delete_company).at_least(1)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).at_least(3)
          Employee.any_instance.expects(:delete_not_logged_user).at_least(3)
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).at_least(1)
          Employee.any_instance.expects(:check_admin).at_least(1)
          Services::MobileTribe::Connector.any_instance.expects(:remove_association).at_least(1)

          @user.destroy
          assert !@user.errors.empty?
          assert_nil User.find_by_id(@user.id)
          @companies.each { |c| assert_nil Company.find_by_id(c.id) }
          @employees.each { |e| assert_nil Employee.find_by_id(e.id) }
          @relate_company_contacts.each { |e| assert_nil Employee.find_by_id(e.id) }

          audit = Audit.last
          assert_equal audit.auditable_id, @user.id
          assert_equal audit.status, Audit::Statuses::FAILED
          assert_equal audit.associations_audits.size, @companies.size
          company_audit = @companies[0]
          assert_equal company_audit.id, @companies[0].id
          assert_equal company_audit.audit.status, Audit::Statuses::FAILED
          assert_equal company_audit.audit.associations_audits.size, 2
          assert_equal company_audit.audit.associations_audits[0].status, Audit::Statuses::FAILED
        end
      end
      should "don't remove user when company remove portals connections error happened, but remove company employees" do
        assert_difference 'Audit.count', 5 do
          Services::OnDeego::OauthClient.any_instance.expects(:delete_company).raises(Services::OnDeego::Errors::OnDeegoError)
          Services::Sogo::Wrapper.any_instance.expects(:delete_user).at_least(3)
          Services::MobileTribe::Connector.any_instance.expects(:remove_calendar_and_mail).at_least(3)
          Employee.any_instance.expects(:delete_not_logged_user).at_least(3)
          Services::OnDeego::OauthClient.any_instance.expects(:delete_employee).at_least(1)
          Employee.any_instance.expects(:check_admin).at_least(1)
          Services::MobileTribe::Connector.any_instance.expects(:remove_association).at_least(1)

          @user.destroy
          assert !@user.errors.empty?
          assert_nil User.find_by_id(@user.id)
          @companies.each { |c| assert_nil Company.find_by_id(c.id) }
          @employees.each { |e| assert_nil Employee.find_by_id(e.id) }
          @relate_company_contacts.each { |e| assert_nil Employee.find_by_id(e.id) }
        end
      end
    end
  end

  context "On create" do
    should "with right " do
      assert_difference 'User.count' do
        user = create_user
        assert_valid user
        assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
      end
    end
    should "with the same username " do
      assert_no_difference 'User.count' do
        user = create_user(:email => users(:ben).email)
        assert user.new_record?
        assert user.errors.on( :email)
      end
    end
  end

  context "On profile_complete" do
    should "with 4 complete fields" do
      user = create_user
      assert_equal user.profile_complete, 26
    end
  end


  protected

  def create_user options = {}
    User.create(user_options(options))
  end

  def user_options options = {}
    {
        :email => "test_user@gmail.com",
        :firstname => "name",
        :lastname => "name",
        :password => "123456",
        :password_confirmation => "123456",
        :login => "test user"
    }.merge(options)
  end
end
