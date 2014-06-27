require "spec_helper"

describe Admin::ApplicationsController do
  it { should be }

  describe 'When logged in' do
    describe 'on GET #index' do
      before(:each) { get :index }

      xit { should render_template :index }
    end

    describe 'on GET #show' do
      before(:each) { get :show }
      #it { should render_template :show }
    end
  end
end
