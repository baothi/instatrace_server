class CreateLocationsShipments < ActiveRecord::Migration
  def self.up
    create_table :locations_shipments, :id => false do |t|
      t.integer :location_id
      t.integer :shipment_id
    end
  end

  def self.down
    drop_table :locations_shipments
  end
end
