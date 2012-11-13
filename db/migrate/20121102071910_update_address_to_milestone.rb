class UpdateAddressToMilestone < ActiveRecord::Migration
  def self.up
  	milestones = Milestone.where("latitude != '0.000000' AND longitude != '0.000000' AND shipment_id in (SELECT id FROM shipments)")
  		
   	milestones.each do |milestone| 		
		  geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]
         
		  if geo		  	
        if geo.data["address_components"] &&  geo.data["address_components"][5] && geo.data["address_components"][5]["short_name"]
          milestone.address = geo.city + ", " + geo.data["address_components"][5]["short_name"]
        else
          milestone.address = geo.city + ", " + geo.state
        end
		  	 
        puts "==============Update milestone_id: #{milestone.id} with #{milestone.address}=================="
  		  milestone.save       
  		  
		  end
  		
   	end

  end

  def self.down
  end
end
