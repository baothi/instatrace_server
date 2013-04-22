class AddFieldIsactivatedToUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t| 
      t.string :is_activated, :default => "N"
    end
  end

  def self.down
    remove_column :users, :is_activated
  end
end
