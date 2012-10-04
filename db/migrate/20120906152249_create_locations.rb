class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.integer :driver_id
      t.integer :shipment_id
      t.float :latitude
      t.float :longitude
      t.string :address

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
