class AddAddressToMilestone < ActiveRecord::Migration
  def self.up
    add_column 'milestones', 'address', :string
  end

  def self.down
    remove_column 'milestones', 'address'
  end
end
