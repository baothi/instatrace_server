class ChangeSpecialInstructionToText < ActiveRecord::Migration
  def self.up
      change_column :shipments, :special_instructions, :text
  end

  def self.down
      change_column :shipments, :special_instructions, :string
  end
end
