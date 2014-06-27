require "spec_helper"

describe User do
  it { Factory.build(:user).should be_valid }
end
