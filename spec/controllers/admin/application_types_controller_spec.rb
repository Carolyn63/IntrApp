require "spec_helper"

describe Admin::ApplicationTypesController do
  describe 'When logged in' do
    before(:each) { controller.stub(:require_user).and_return(true) }

    describe 'on GET #index' do
      before(:each) { get :index }

      it { should render_template :index }
      it { should respond_with :success }
      it { should assign_to :application_types }
    end

  end
end
