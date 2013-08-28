class AddFieldIsPostShipmentToShipments < ActiveRecord::Migration
  def self.up
    change_table :shipments do |t| 
      t.column :is_post_shipment, :boolean
    end
  end

  def self.down
    remove_column :shipments, :is_post_shipment
  end
end
