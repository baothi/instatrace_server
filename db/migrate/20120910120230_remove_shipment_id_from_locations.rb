class RemoveShipmentIdFromLocations < ActiveRecord::Migration
  def self.up
    remove_column :locations, :shipment_id
  end

  def self.down
    add_column :locations, :shipment_id, :integer
  end
end
