class AddTimezoneColumnToLocations < ActiveRecord::Migration
  def self.up
  	add_column 'locations', :timezone, :decimal, :precision => 2, :scale => 1, :null => true
  end

  def self.down
  	remove_column 'locations', :timezone
  end
end
