require "spec_helper"

describe Typization do
  it { Factory(:typization).should be_valid }

  it { should belong_to :application }
  it { should belong_to :application_type }

  it { should validate_presence_of :application }
  it { should validate_presence_of :application_type }

  xit { should validate_uniqueness_of(:application_type_id).scoped_to(:application_id) }
end
