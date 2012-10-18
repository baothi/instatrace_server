class CreatePieces < ActiveRecord::Migration
  def self.up
    create_table :pieces do |t|
      t.integer :pieces
      t.float :weight
      t.float :length
      t.float :height
      t.integer :shipment_id
      t.timestamps
    end
  end

  def self.down
    drop_table :pieces
  end
end
