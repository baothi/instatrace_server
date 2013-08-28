class AddFreightForwarderCodeToShipments < ActiveRecord::Migration
  def self.up
      add_column :shipments,:freight_forwarder_code, :string, :limit => 3
  end

  def self.down
    remove_column :shipments, :freight_forwarder_code
  end
end
