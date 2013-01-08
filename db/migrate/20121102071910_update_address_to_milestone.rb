class UpdateAddressToMilestone < ActiveRecord::Migration
  def self.up
  	milestones = Milestone.where("latitude != '0.000000' AND longitude != '0.000000' AND shipment_id in (SELECT id FROM shipments)")
  		
   	milestones.each do |milestone| 	
      puts "====Start milestone: #{milestone.id}, lat: #{milestone.latitude}, long: #{milestone.longitude}"	
		  geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]

		  if geo && geo.city && geo.state_code
        milestone.address = geo.city + ", " + geo.state_code
		  	 
        puts "==============Update milestone_id: #{milestone.id} with #{milestone.address}=================="
  		  milestone.save       
  		  
		  end
  		
   	end

  end

  def self.down
  end
end
