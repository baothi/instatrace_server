class UpdateHawbNeedRunGetFsaFile < ActiveRecord::Migration
  def self.up
    @shipments = Shipment.where(:hawb => [2215024, 345010])
    @shipments.each do |s|
      s.updated_at = Time.now
      s.save
    end
  end

  def self.down
  end
end
