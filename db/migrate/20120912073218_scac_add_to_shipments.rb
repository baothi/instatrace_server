class ScacAddToShipments < ActiveRecord::Migration
  def self.up
  	add_column 'shipments', 'carrier_scac_code', :string, :limit => 15
  	add_column 'shipments', 'receiver_scac_code', :string, :limit => 15
  end

  def self.down
  	remove_column 'shipments', 'carrier_scac_code'
  	remove_column 'shipments', 'receiver_scac_code'
  end
end
