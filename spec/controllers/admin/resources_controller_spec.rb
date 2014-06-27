require "spec_helper"

# class FooBar; end

describe Admin::ResourcesController do
  it { controller.stub(:resource_class).and_return(mock(:name => 'FooBar')); controller.send(:resource_class_as_sym).should eql :foo_bar }
end
