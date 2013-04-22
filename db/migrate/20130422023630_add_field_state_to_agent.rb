class AddFieldStateToAgent < ActiveRecord::Migration
  def self.up
    change_table :agents do |t| 
      t.string :state
    end
  end

  def self.down
    remove_column :agents, :state
  end
end
