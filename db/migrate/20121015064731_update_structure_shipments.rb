class UpdateStructureShipments < ActiveRecord::Migration
 def self.up
    
		rename_column 'shipments', 'ship', 'ship_date'
		rename_column 'shipments', 'delivery', 'delivery_date'
		rename_column 'shipments', 'pieces', 'pieces_total'

    add_column 'shipments', 'origin_address1', :string
    add_column 'shipments', 'origin_address2', :string
    add_column 'shipments', 'origin_city', :string
    add_column 'shipments', 'origin_state', :string
    add_column 'shipments', 'origin_zip_postal_code', :string
    add_column 'shipments', 'origin_country', :string

    add_column 'shipments', 'dest_address1', :string
    add_column 'shipments', 'dest_address2', :string
    add_column 'shipments', 'dest_city', :string
    add_column 'shipments', 'dest_state', :string
    add_column 'shipments', 'dest_zip_postal_code', :string
    add_column 'shipments', 'dest_country', :string

    add_column 'shipments', 'length', :float
    add_column 'shipments', 'height', :float

		add_column 'shipments', 'service_level_code', :string, :limit => 2
		add_column 'shipments', 'pick_up_and_delivery_instructions', :string, :limit => 2
		add_column 'shipments', 'shipment_types', :string, :limit => 2

		    
  end

  def self.down
    rename_column 'shipments', 'ship_date', 'ship'
		rename_column 'shipments', 'delivery_date', 'delivery'
		rename_column 'shipments', 'pieces_total', 'pieces'

		remove_column 'shipments', 'origin_address1'
		remove_column 'shipments', 'origin_address2'
		remove_column 'shipments', 'origin_city'
		remove_column 'shipments', 'origin_state'
		remove_column 'shipments', 'origin_zip_postal_code'
		remove_column 'shipments', 'origin_country'

		remove_column 'shipments', 'dest_address1'
		remove_column 'shipments', 'dest_address2'
		remove_column 'shipments', 'dest_city'
		remove_column 'shipments', 'dest_state'
		remove_column 'shipments', 'dest_zip_postal_code'
		remove_column 'shipments', 'dest_country'

    remove_column 'shipments', 'length'
		remove_column 'shipments', 'height'
		remove_column 'shipments', 'service_level_code'
		remove_column 'shipments', 'pick_up_and_delivery_instructions'
		remove_column 'shipments', 'shipment_types'
		
  end


end
