class UpdateAddressToMilestone < ActiveRecord::Migration
  def self.up
  	milestones = Milestone.where("latitude != '0.000000' AND longitude != '0.000000' AND shipment_id in (SELECT id FROM shipments)")
  		
   	milestones.each do |milestone| 		
		  geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]
		  if geo		  	
		  	milestone.address = geo.city + ", " + geo.state		  	
  		  milestone.save
  		  puts "==============Update milestone_id: #{milestone.id} with #{milestone.address}=================="
		  end
  		
   	end

  end

  def self.down
  end
end
