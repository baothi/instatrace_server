class AddFieldsToShipments < ActiveRecord::Migration
   def self.up
    add_column 'shipments', 'piece_count', :integer
    add_column 'shipments', 'special_instructions', :string
    add_column 'shipments', 'dangerous_goods', :boolean, :default => 0
    
     change_table :shipments do |t|
      t.change :origin_country, :string, :limit => 2
      t.change :dest_country, :string, :limit => 2
     end
  end

  def self.down
    remove_column 'shipments', 'piece_count'
    remove_column 'shipments', 'special_instructions'
    remove_column 'shipments', 'dangerous_goods'
  end
end
