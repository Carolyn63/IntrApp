require "spec_helper"

describe Admin::CategoriesController do
  #integrate_views

  describe 'When logged in' do
    before(:each) { controller.stub(:require_user).and_return(true) }

    describe 'on GET #index' do
      before(:each) { get :index }

      it { should render_template :index }
      it { should respond_with :success }
      it { should assign_to :categories }
    end

    describe 'on GET #show' do
      before(:each) do
        @category = Factory(:category)
        get :show, :id => @category
      end
      it { should respond_with :success }
      it { should render_template :show }
    end

    describe 'on GET #new' do
      before(:each) { get :new }

      it { should respond_with :success }
      it { should render_template :new }
      it { should assign_to :category }
    end

    describe 'on DELETE #destroy' do
      before(:each) do
        @category = Factory(:category)
        delete :destroy, :id => @category
      end

      xit { should respond_with :redirect }
      it { puts response.status }
      it { puts flash.inspect }
    end

  end

end
