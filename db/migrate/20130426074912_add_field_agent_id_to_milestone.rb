class AddFieldAgentIdToMilestone < ActiveRecord::Migration
  def self.up
    change_table :milestones do |t| 
      t.integer :agent_id
    end
  end

  def self.down
    remove_column :milestones, :agent_id
  end
end
