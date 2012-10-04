class AddIndexToTableShipmentsLocationsShipmentsMilestones < ActiveRecord::Migration
   def self.up
    add_index :shipments, :hawb
    add_index :locations_shipments, :location_id
    add_index :milestones, :driver_id
    add_index :milestones, :shipment_id
    add_index :milestones, :action
  end

  def self.down
    remove_index :shipments, :column => :hawb
    remove_index :locations_shipments, :column => :location_id
    remove_index :milestones, :column => :driver_id
    remove_index :milestones, :column => :shipment_id
    remove_index :milestones, :column => :action
  end
end
