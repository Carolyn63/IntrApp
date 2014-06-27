require "spec_helper"

describe CompaniesController do
  describe 'When logged in' do
    before(:each) { controller.stub(:require_user).and_return(true) }
  end
end
