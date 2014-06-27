require 'spec_helper'

describe Devicefication do
  it { should belong_to :application }
  it { should belong_to :device }

  it { should validate_presence_of :application }
  it { should validate_presence_of :device }
  xit { should validate_uniqueness_of(:application_id).scoped_to(:device_id) }
end
