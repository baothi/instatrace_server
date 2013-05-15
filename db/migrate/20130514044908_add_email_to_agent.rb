class AddEmailToAgent < ActiveRecord::Migration
  def self.up
    change_table :agents do |t| 
      t.string :email
    end
  end

  def self.down
    remove_column :agents, :email
  end
end
