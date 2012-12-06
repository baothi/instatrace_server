class AddActionCodeMilestones < ActiveRecord::Migration
   def self.up
    add_column 'milestones', 'action_code', :string, :limit => 50
  end

  def self.down
    remove_column 'milestones', 'action_code'
  end
end
