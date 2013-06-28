class UpdateActioncodeForMilestones < ActiveRecord::Migration
  def self.up
  	milestones = Milestone.where("action !='' and action is not null and driver_id is not null and driver_id !=''")
    	
   	milestones.each do |milestone|           
      if milestone.action.to_s.eql?("pick-up")
      	milestone.action_code = "RT2"#"X9"#"RT2"     	

      elsif milestone.action.to_s.eql?("back_at_base")
      	milestone.action_code = "BAB"

      elsif milestone.action.to_s.eql?("en_route_to_carrier")
      	milestone.action_code = "RT5"

      elsif milestone.action.to_s.eql?("tendered_to_carrier")
      	milestone.action_code = "TND"

      elsif milestone.action.to_s.eql?("recovered_from_carrier")
      	milestone.action_code = "REC"

      elsif milestone.action.to_s.eql?("out_for_delivery")
      	milestone.action_code = "OFD" #"J1"

      elsif milestone.action.to_s.eql?("delivered")
      	milestone.action_code = "IDL"

      elsif milestone.action.to_s.eql?("completed_unloading/recovered")
      	milestone.action_code = "D1"

      elsif milestone.action.to_s.eql?("arrived_transfer_terminal")
      	milestone.action_code = "X4"

      elsif milestone.action.to_s.eql?("departed_transfer_terminal")
      	milestone.action_code = "P1"

      elsif milestone.action.to_s.eql?("departed_origin_erminal")
      	milestone.action_code = "AF"
        milestone.action = 'departed_origin_terminal'

      elsif milestone.action.to_s.eql?("arrived_destination_terminal")
      	milestone.action_code = "X1"     
      		
      end
		  
      unless milestone.save!
        
        @errors << {
          :shipment_id => milestone.id,
          :message => milestone.errors.full_messages.join("; "),
          :full_message => "Milestone (#{milestone.id}) was not saved due to next errors: #{milestone.errors.full_messages.join("; ")}"
        }
        puts self.errors.last[:full_message]
      end
      Rails.logger.info "***********Updated milestone #ID: #{milestone.id}"  
      puts "**********Updated milestone #ID: #{milestone.id}"  

   	end
  end

  def self.down
  end
end
