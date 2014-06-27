require "spec_helper"

describe Admin::DevicesController do
  it { should be }

  describe 'User logger in' do
    before(:each) do
      controller.stub(:require_user).and_return(true)
    end

    describe 'on GET #index' do
      before(:each) { get :index }

      it { should respond_with :success }
      it { should render_template :index }
    end

    describe 'on GET #show' do
      before(:each) { get :show, :id => Factory(:device) }

      it { should render_template :show }
      xit { should respond_with :success }
    end

    describe 'on GET #new' do
      before(:each) { get :new }

      it { should render_template :new }
      it { should respond_with :success }
      #it { should assign_to :device }
    end

    describe 'on POST #create' do

      context 'success' do
        before(:each) { @device_attributes = Factory.attributes_for(:device);  post :create, :device => @device_attributes }
        xit { should redirect_to :show }
        it { should assign_to :device }
        it { flash[:notice].should eql "Device was successfully created." }
      end

      context 'failure' do
        before(:each) { @device_attributes = Factory.attributes_for(:device)
          post :create, :device => {}
        }

        xit { should render_template :new }
        it { should assign_to :device }
        # it { should respond_with :redirect }
      end

    end

    describe 'on PUT #update' do
      context 'success' do
      end

      context 'failure' do
      end
    end

    describe 'on DELETE #destroy' do
      before(:each) do
        @device = Factory(:device)
        delete :destroy, :id => @device.id
      end
      xit { should respond_with :redirect }
      xit { should redirect_to admin_devices_path }
    end

  end
end
