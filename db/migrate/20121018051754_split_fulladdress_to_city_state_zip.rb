class SplitFulladdressToCityStateZip < ActiveRecord::Migration
  def self.up
  	shipments = Shipment.all
  	shipments.each do |shipment|
  		origin = shipment.origin.split(',') if shipment.origin
  	 
	  	 if origin && origin.count > 2
	  	 		 shipment.origin_address1 = origin[0]
			  	 shipment.origin_state = origin[1]
			  	 shipment.origin_zip_postal_code = origin[2]		  
			  	 puts "Updating Origin: #{shipment.origin}"
	  	 end

	  	 destination = shipment.destination.split(',') if shipment.destination
	  	 
	  	 if destination && destination.count > 2
	  	 		 shipment.dest_address1 = destination[0]
			  	 shipment.dest_state = destination[1]
			  	 shipment.dest_zip_postal_code = destination[2]			  	 
			  	 puts "Updating Destination: #{shipment.destination}"
	  	 end
  	
		 	 shipment.save
  	end
  end


  def self.down
  end
end
