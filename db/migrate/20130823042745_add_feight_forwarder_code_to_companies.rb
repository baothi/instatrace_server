class AddFeightForwarderCodeToCompanies < ActiveRecord::Migration
  def self.up
      add_column :companies,:freight_forwarder_code, :string, :limit => 3
  end

  def self.down
    remove_column :companies, :freight_forwarder_code
  end
end
