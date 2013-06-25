class AddDamagedNotifyToMilestone < ActiveRecord::Migration
  def self.up
    change_table :milestones do |t| 
      t.column :damaged_notifier, :boolean
    end
  end

  def self.down
    remove_column :milestones, :damaged_notifier
  end
end
