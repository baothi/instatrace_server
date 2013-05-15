class AddEmailToCompanies < ActiveRecord::Migration
  def self.up
    change_table :companies do |t| 
      t.string :email
    end
  end

  def self.down
    remove_column :companies, :email
  end
end
