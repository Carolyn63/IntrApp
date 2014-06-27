require File.dirname(__FILE__) + '/../test_helper'

class HelpUrlTest < ActiveSupport::TestCase
  context "the HelpUrl class" do
    should_validate_presence_of :name, :portal_url, :help_url

    context "On create" do
      should "with right params" do
        assert_difference('HelpUrl.count') do
          url = create_help_url
          assert_valid url
          assert !url.new_record?, "#{url.errors.full_messages.to_sentence}"
          assert_equal url.action_name, "index"
          assert_equal url.controller_name, "dashboard"
          assert url.url_params.blank?
          assert_equal url.portal_url, "/users/:id/dashboard"
        end
      end
      should "parse url with params" do
        assert_difference('HelpUrl.count') do
          url = create_help_url(:portal_url => "/users/1/employers?status=rejected")
          assert_valid url
          assert !url.new_record?, "#{url.errors.full_messages.to_sentence}"
          assert_equal url.action_name, "index"
          assert_equal url.controller_name, "employers"
          assert_equal url.url_params, "status=rejected"
          assert_equal url.portal_url, "/users/:id/employers?status=rejected"
        end
      end
      should "don't change portal url" do
        assert_difference('HelpUrl.count') do
          url = create_help_url(:portal_url => "/signup")
          assert_valid url
          assert !url.new_record?, "#{url.errors.full_messages.to_sentence}"
          assert_equal url.action_name, "new"
          assert_equal url.controller_name, "users"
          assert url.url_params.blank?
          assert_equal url.portal_url, "/signup"
        end
      end
      should "with wrong portal_url" do
        assert_no_difference('HelpUrl.count') do
          url = create_help_url(:portal_url => "/wrong_url")
          assert url.errors.on(:portal_url)
        end
      end
      should "return error for duplicate portal url" do
        assert_no_difference('HelpUrl.count') do
          url = create_help_url(:portal_url => "/users/1/employers")
          assert url.errors.on(:portal_url)
        end
      end
    end

    context "find_help_url method" do
      setup do
        @params = {:controller => "employers", :action => "index"}
      end
      should "return right url without params" do
        assert_equal HelpUrl.find_help_url(@params), help_urls(:pending_employee_url).help_url
        assert_equal HelpUrl.find_help_url({:controller => "users", :action => "index"}), help_urls(:users_url).help_url
      end
      should "return right url for pending employers" do
        assert_equal HelpUrl.find_help_url(@params.merge(:url_params => "status=pending")), help_urls(:pending_employee_url).help_url
        assert_equal HelpUrl.find_help_url(@params.merge(:url_params => "status=pending&page=1")), help_urls(:pending_employee_url).help_url
      end
      should "return right url for active employers" do
        assert_equal HelpUrl.find_help_url(@params.merge(:url_params => "status=active")), help_urls(:active_employee_url).help_url
        assert_equal HelpUrl.find_help_url(@params.merge(:url_params => "status=active&page=1")), help_urls(:active_employee_url).help_url
      end
      should "return url without params if url by params not found" do
        assert_equal HelpUrl.find_help_url(@params.merge(:url_params => "status=not_exist")), help_urls(:pending_employee_url).help_url
      end
    end
  end

  context "An Instance" do
    setup do
      @url = help_urls(:url_001)
    end
  end

  
  protected

  def create_help_url options = {}
    HelpUrl.create({
        :name => "Dashboard",
        :portal_url => "/users/1/dashboard",
        :help_url => "http://docs.futurewei.ebento.net/display/eBento/Portal+Home"
      }.merge(options))
  end

end
