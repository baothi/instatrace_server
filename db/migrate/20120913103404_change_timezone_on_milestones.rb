class ChangeTimezoneOnMilestones < ActiveRecord::Migration
  def self.up
  	change_column 'milestones', :timezone, :decimal, :precision => 2, :scale => 1, :null => true
  	change_column_default 'milestones', :timezone, nil
  end

  def self.down
  end
end
