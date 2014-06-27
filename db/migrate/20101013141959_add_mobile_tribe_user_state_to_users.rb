class AddMobileTribeUserStateToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :mobile_tribe_user_state, :integer, :default => User::MobileTribeUserState::NOT_EXIST, :null => false
  end

  def self.down
    remove_column :users, :mobile_tribe_user_state
  end
end
