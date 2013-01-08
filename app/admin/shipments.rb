ActiveAdmin.register Shipment do

  menu :if => proc{ can?(:update, Shipment) }
  controller.authorize_resource

  # table for index action
  index do
    column(:hawb) {|s| link_to s.hawb, admin_shipment_path(s)}
    column :service_level
    column :mawb
    column :pieces_total
    column("Weight") { |s| "#{number_with_delimiter(s.weight.to_i)} Lb." }
    column(:origin) { |s| raw "#{s.origin}" }       
    column(:destination) { |s| raw "#{s.destination}" }  
    column :shipper
    column :consignee   
    column :ship_date
    column :delivery_date
    column :dangerous_goods
    column :special_instructions
    column "Registered", :created_at
  end

  # table for show action
  show :title => :shipment_id do |s|
    attributes_table do
      row :shipment_id
      row :service_level
      row :hawb
      row :mawb
      row :pieces_total
      row (:weight) { "#{number_with_delimiter(s.weight.to_i)} Lb." }
      row (:origin) { raw "#{s.origin}"}  
      row (:destination) {raw "#{s.destination}"}  
      row :shipper
      row :consignee     
      row :ship_date
      row :delivery_date
      row :special_instructions
      row :dangerous_goods
    end
    active_admin_comments
  end
  
  # form for new/edit actions
  form do |f|
    f.inputs "Shipment Details" do
      f.input :shipment_id
      f.input :service_level
      f.input :hawb
      f.input :mawb
      f.input :pieces_total
      f.input :weight
      #f.input :origin
      f.input :origin_address1
      f.input :origin_address2
      f.input :origin_city
      f.input :origin_state
      f.input :origin_zip_postal_code
      f.input :origin_country
      #f.input :destination
      f.input :dest_address1
      f.input :dest_address2
      f.input :dest_city
      f.input :dest_state
      f.input :dest_zip_postal_code
      f.input :dest_country
      f.input :shipper
      f.input :consignee
      f.input :ship_date
      f.input :delivery_date
    end
    f.buttons
  end

  collection_action :update, :method => :put do
      @shipment = Shipment.find(params[:id])
                
      #Concat origin data
      # if params[:shipment][:origin_address1] && !params[:shipment][:origin_address1].blank?
      #     @shipment.origin =  params[:shipment][:origin_address1]           
      # end
      
      # if params[:shipment][:origin_address2] && !params[:shipment][:origin_address2].blank?        
      #   @shipment.origin <<  "<br/>" + params[:shipment][:origin_address2] + "<br/>"
      #   @shipment.origin_address2 =  params[:shipment][:origin_address2] 
      # end       

      # @shipment.origin << params[:shipment][:origin_city]
      # if params[:shipment][:origin_state] && !params[:shipment][:origin_state].blank?
      #   @shipment.origin << ", "
      # end  
      #  @shipment.origin << params[:shipment][:origin_state]   + " " + params[:shipment][:origin_zip_postal_code] 
      
      # #Concat destination data     
      # if params[:shipment][:dest_address1] && !params[:shipment][:dest_address1].blank?
      #   @shipment.destination =  params[:shipment][:dest_address1] 
      # end
      
      # if params[:shipment][:dest_address2] && !params[:shipment][:dest_address2].blank?
      #   @shipment.destination <<  "<br/>" + params[:shipment][:dest_address2] + "<br/>"
      # end               
      # @shipment.destination <<  params[:shipment][:dest_city] 
      # if params[:shipment][:dest_state] && !params[:shipment][:dest_state].blank?
      #    @shipment.destination << ", "
      # end

      # @shipment.destination << params[:shipment][:dest_state]   + " " + params[:shipment][:dest_zip_postal_code] 

      # @shipment.origin_address1 =  params[:shipment][:origin_address1]
      # @shipment.origin_address2 =  params[:shipment][:origin_address2]
      # @shipment.origin_state = params[:shipment][:origin_state]
      # @shipment.origin_city = params[:shipment][:origin_city]
      # @shipment.origin_zip_postal_code = params[:shipment][:origin_zip_postal_code]

      # @shipment.dest_address1 = params[:shipment][:dest_address1]
      # @shipment.dest_address2 = params[:shipment][:dest_address2]
      # @shipment.dest_state = params[:shipment][:dest_state]
      # @shipment.dest_city = params[:shipment][:dest_city]
      # @shipment.dest_zip_postal_code = params[:shipment][:dest_zip_postal_code]

      # @shipment.shipment_id = params[:shipment][:shipment_id]
      # @shipment.service_level = params[:shipment][:service_level]
      # @shipment.pieces_total = params[:shipment][:pieces_total]
      # @shipment.weight = params[:shipment][:weight]
      # @shipment.shipper = params[:shipment][:shipper]
      # @shipment.consignee = params[:shipment][:consignee]

      # ship_date = params[:shipment]["ship_date(1i)"]<<"-"<< params[:shipment]["ship_date(2i)"]<<"-"<<params[:shipment]["ship_date(3i)"]<<" "<<params[:shipment]["ship_date(4i)"]<<":"<<params[:shipment]["ship_date(5i)"]<<":00"
      # @shipment.ship_date = Date.strptime(ship_date, '%Y-%m-%d %H:%M:%S') rescue nil
      # delivery_date = params[:shipment]["delivery_date(1i)"]<<"-"<< params[:shipment]["delivery_date(2i)"]<<"-"<<params[:shipment]["delivery_date(3i)"]<<" "<<params[:shipment]["delivery_date(4i)"]<<":"<<params[:shipment]["delivery_date(5i)"]<<":00"
      # @shipment.delivery_date = Date.strptime(delivery_date, '%Y-%m-%d %H:%M:%S') rescue nil 
     
      # @shipment.save
      set_shipment_data params,@shipment
    
      redirect_to admin_shipment_path(@shipment.id) 
  end

  collection_action :create, :method => :post do
      @shipment = Shipment.new params[:shipment]
     
      set_shipment_data params,@shipment
       
      redirect_to admin_shipment_path(@shipment.id) 
  end

  

  controller do
    def set_shipment_data (params, shipment)
      #Concat origin data
      if params[:shipment][:origin_address1] && !params[:shipment][:origin_address1].blank?
          shipment.origin =  params[:shipment][:origin_address1]           
      end
      
      if params[:shipment][:origin_address2] && !params[:shipment][:origin_address2].blank?        
        shipment.origin +=  "<br/>" + params[:shipment][:origin_address2] + "<br/>"        
      end       

      if shipment.origin
         shipment.origin += params[:shipment][:origin_city]
      else
         shipment.origin = params[:shipment][:origin_city]
      end
      
      if params[:shipment][:origin_state] && !params[:shipment][:origin_state].blank?
        shipment.origin += ", "
      end  
       shipment.origin += params[:shipment][:origin_state]   + " " + params[:shipment][:origin_zip_postal_code] + " " + params[:shipment][:origin_country]
      
      #Concat destination data     
      if params[:shipment][:dest_address1] && !params[:shipment][:dest_address1].blank?
        shipment.destination =  params[:shipment][:dest_address1] 
      end
      
      if params[:shipment][:dest_address2] && !params[:shipment][:dest_address2].blank?
        shipment.destination +=  "<br/>" + params[:shipment][:dest_address2] + "<br/>"
      end    
      if shipment.destination
         shipment.destination +=  params[:shipment][:dest_city] 
      else
         shipment.destination =  params[:shipment][:dest_city] 
      end
      
      if params[:shipment][:dest_state] && !params[:shipment][:dest_state].blank?
         shipment.destination += ", "
      end

      shipment.destination += params[:shipment][:dest_state]   + " " + params[:shipment][:dest_zip_postal_code] + " "  + params[:shipment][:dest_country]

      shipment.origin_address1 =  params[:shipment][:origin_address1]
      shipment.origin_address2 =  params[:shipment][:origin_address2]
      shipment.origin_state = params[:shipment][:origin_state]
      shipment.origin_city = params[:shipment][:origin_city]
      shipment.origin_zip_postal_code = params[:shipment][:origin_zip_postal_code]
      shipment.origin_country = params[:shipment][:origin_country]

      shipment.dest_address1 = params[:shipment][:dest_address1]
      shipment.dest_address2 = params[:shipment][:dest_address2]
      shipment.dest_state = params[:shipment][:dest_state]
      shipment.dest_city = params[:shipment][:dest_city]
      shipment.dest_zip_postal_code = params[:shipment][:dest_zip_postal_code]
      shipment.dest_country = params[:shipment][:dest_country]

      shipment.pieces_total = params[:shipment][:piece_count]
      shipment.special_instructions = params[:shipment][:special_instructions]
      shipment.dangerous_goods = params[:shipment][:dangerous_goods]

      shipment.shipment_id = params[:shipment][:shipment_id]
      shipment.service_level = params[:shipment][:service_level]
      shipment.pieces_total = params[:shipment][:pieces_total]
      shipment.weight = params[:shipment][:weight]
      shipment.shipper = params[:shipment][:shipper]
      shipment.consignee = params[:shipment][:consignee]

      ship_date = params[:shipment]["ship_date(1i)"]<<"-"<< params[:shipment]["ship_date(2i)"]<<"-"<<params[:shipment]["ship_date(3i)"]<<" "<<params[:shipment]["ship_date(4i)"]<<":"<<params[:shipment]["ship_date(5i)"]<<":00"
      shipment.ship_date = Date.strptime(ship_date, '%Y-%m-%d %H:%M:%S') rescue nil
      delivery_date = params[:shipment]["delivery_date(1i)"]<<"-"<< params[:shipment]["delivery_date(2i)"]<<"-"<<params[:shipment]["delivery_date(3i)"]<<" "<<params[:shipment]["delivery_date(4i)"]<<":"<<params[:shipment]["delivery_date(5i)"]<<":00"
      shipment.delivery_date = Date.strptime(delivery_date, '%Y-%m-%d %H:%M:%S') rescue nil 
     
      shipment.save
    end
  end
  



end

