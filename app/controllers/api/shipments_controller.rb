class Api::ShipmentsController < Api::ApiController
  before_filter :get_shipment, :except => [:mass_update ,:post_shipment]
  include ActionView::Helpers
  
  def show
    current_user.current_milestone.update_attributes :shipment_id => @shipment.id, :damaged => @shipment.damaged?#, :damage_desc => @shipment.damage_desc
    render :json => @shipment
  end
  def post_shipment               
    if params[:shipment]        
        #Update params data because of update_attributes rails rules
        if params[:shipment][:pieces].present?
           params[:shipment][:pieces_attributes] = params[:shipment][:pieces]
           params[:shipment].delete :pieces           
        end 
        #truncate leading 3 digits from hawb
        params[:shipment][:hawb] = params[:shipment][:hawb][3..-1]
        
        @shipment = Shipment.find_by_hawb(params[:shipment][:hawb])
        
        if @shipment            
            @shipment.pieces.delete_all            
            @shipment.update_attributes(params[:shipment])
        else
           @shipment = Shipment.new params[:shipment]           
        end
        
        @shipment.origin =  params[:shipment][:origin_address1] 
        if params[:shipment][:origin_address2] 
           @shipment.origin += "<br/>" + params[:shipment][:origin_address2] + "<br/>"
        end   
        origin_country_name = COUNTRY_CODE['countrycode'][params[:shipment][:origin_country]] 
        @shipment.origin += params[:shipment][:origin_city] + ", " + params[:shipment][:origin_state]   + " " + params[:shipment][:origin_zip_postal_code]  + "<br/>" + origin_country_name
        
        @shipment.origin_address1 = params[:shipment][:origin_address1]
        @shipment.origin_address2 = params[:shipment][:origin_address2]
        @shipment.origin_city = params[:shipment][:origin_city]
        @shipment.origin_state = params[:shipment][:origin_state]
        @shipment.origin_zip_postal_code = params[:shipment][:origin_zip_postal_code]
        @shipment.origin_country = params[:shipment][:origin_country]


        @shipment.destination = params[:shipment][:dest_address1] 
        if params[:shipment][:dest_address2]
           @shipment.destination += "<br/>" + params[:shipment][:dest_address2] + "<br/>" 
        end 
        dest_country_name = COUNTRY_CODE['countrycode'][params[:shipment][:dest_country]] 
        
        @shipment.destination += params[:shipment][:dest_city] +  ", " +  params[:shipment][:dest_state]  +  " "  +    params[:shipment][:dest_zip_postal_code]  + "<br/>"  + dest_country_name
        @shipment.dest_address1 = params[:shipment][:dest_address1]
        @shipment.dest_address2 = params[:shipment][:dest_address2]
        @shipment.dest_city = params[:shipment][:dest_city]
        @shipment.dest_state = params[:shipment][:dest_state]
        @shipment.dest_zip_postal_code = params[:shipment][:dest_zip_postal_code]
        @shipment.dest_country = params[:shipment][:dest_country]
        # Get value of piece_count as total of pieces
        @shipment.pieces_total = params[:shipment][:piece_count]
        @shipment.special_instructions = params[:shipment][:special_instructions]
        @shipment.dangerous_goods = params[:shipment][:dangerous_goods]

        #@shipment.ship_date = Date.strptime(params[:shipment][:ship_date], '%Y-%m-%d %H:%M:%S') rescue nil
        #@shipment.delivery_date = Date.strptime(params[:shipment][:delivery_date], '%Y-%m-%d %H:%M:%S') rescue nil   

        @shipment.ship_date = params[:shipment][:ship_date]
        @shipment.delivery_date = params[:shipment][:delivery_date]     
        valid = true
        message = ''
        if params[:shipment][:dangerous_goods] != '0' && params[:shipment][:dangerous_goods] != '1'
            message = 'The dangerous_goods field requires value 0 or 1'
            valid = false
        end
        if (params[:shipment][:origin_country] !=0 && params[:shipment][:origin_country].length != 2 ) || (params[:shipment][:dest_country] !=0 && params[:shipment][:dest_country].length != 2 )
            message = 'The length of country code requires two characters'
            valid = false
        end

        if valid && @shipment.save! 
           piece = Piece.find_by_sql ["SELECT SUM(weight) as weight, SUM(height) as height, SUM(length) as length, count(id) as pieces_total FROM pieces WHERE shipment_id = ? ",@shipment.id]
           if piece     
              piece = piece.first         
              #Update data of shipment table             
              #@shipment.update_attributes(:weight => piece.weight, :height => piece.height, :length => piece.length, :pieces_total => piece.pieces_total )              
              @shipment.update_attributes(:weight => piece.weight, :height => piece.height, :length => piece.length)              
              @shipment.save!            
           end                  
           message = 'Shipment was successfully updated.'        
           render :json => {:status => 200, :message => message}

        else
            render :json => {:status => 400, :message => message}  
        end

    else        
      raise Exception, t('errors.messages.not_found')       
    end
  end

  def mass_update    
     begin
      if params[:data]
        data = ActiveSupport::JSON.decode(params[:data])
      else 
        raise Exception, t('errors.messages.not_found') 
      end 
      ActiveRecord::Base.transaction do
        data.each do |shipment_data|
          shipment = Shipment.api_search(shipment_data['shipment'])
          unless  shipment
            raise Exception, t('errors.messages.not_found')
          end 
          shipment_data['milestone']['driver_id'] = @user.id
          shipment_data['milestone']['damage_desc'] = shipment_data['damage']
          
          action_code = ''
          #Set action_code for new milestone
          if shipment_data["milestone"]["action"]     
           #action_code = TRANSPAK_STATUS['AT7'].select {|k,v| v == shipment_data["milestone"]["action"]} 
           action_code = TRANSPAK_STATUS['AT7'].key(shipment_data["milestone"]["action"])
           
           shipment_data["milestone"]["action_code"] = action_code               
          end 
          
          milestone = shipment.milestones.create(shipment_data['milestone'])
                    
          if  shipment_data['document']
            document = milestone.milestone_documents.build(:doc_type => shipment_data['document']['doc_type'])
            document.name = create_image(shipment_data['document']['name'],'document')
            document.save
          end
          
         if shipment_data['signature']
            sign = milestone.create_signature(:name      => shipment_data['signature']['name'],
                                              :email     => shipment_data['signature']['email'],
                                              :signature => create_image(shipment_data['signature']['signature'],'signature'))
          end
          unless shipment_data['damage_photo'].nil? || shipment_data['damage_photo'].empty?
            shipment_data['damage_photo'].each do |image|
              milestone.damages.create(:photo => create_image(image,"damage"))
            end
          end

           #Check setting
          setting = Setting.find_by_name('EnableWTUpdateStatus')
          if setting && setting.value == '1'
             #hawb = 340510 #For testing
             hawb = shipment.hawb  
             piece_count = shipment.piece_count 

             #Call update status service from WordTrak             
             begin
                client = Savon.client("http://freight.transpak.com/WTKServices/Shipments.asmx?WSDL")
                response = client.request :update_status, body: {"HandlingStation" => "", "HAWB" => hawb, "UserName" => "instatrace", "StatusCode" => action_code} 
                if response.success?
                   data = response.to_array(:update_status_response, :update_status_result).first      
                   if data == true
                      Rails.logger.info "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                   else
                      Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                   end
                 end
                # if milestone && milestone.action.to_s == 'delivered'
                #     login_name = nil
                #     signature_name = nil
                #     delivered_date = nil
                    
                #     if milestone && milestone.signature
                #        login_name = milestone.driver.login
                #        signature_name = milestone.signature.name
                #        zone = RestClient.get("http://api.geonames.org/timezone?lat=#{milestone.latitude}&lng=#{milestone.longitude}&username=instatrace")
                #        timezone = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
                #        delivered_date = milestone.created_at.in_time_zone(timezone).to_s('YYYY-MM-DD HH:MM:SS')
                #     end                
                    
                #     #Call SubmitPOD service from WordTrak  
                #     response = client.request :submit_pod, body: {"UserInitials" => "UserInitials", "HAWB" => hawb, "UserName" => login_name, "PiecesDelivered" => piece_count.to_i, "Signer" => signature_name, "PODDateTime" => "2012-12-20 15:16:24"} 
                #     if response.success?
                #        data = response.to_array(:update_status_response, :update_status_result).first      
                #        if data == true
                #           Rails.logger.info "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                #        else
                #           Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                #        end
                #     end
                # end
                

             rescue Savon::Error => error
                  Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb} #{error}"
             end                      
          end

        end
      end
      render :json => {:status => true, :message => t('messages.notice.milestone_created_ok')}
      rescue ActiveRecord::StatementInvalid, Exception => e
        render :status => 500, :json => {:status => false, :message => e.message};
    end  
  end

 
  
protected
  
  def create_image(data, name)    
    encoded_img = data.sub('data:image/bmp;base64,', '').sub('data:image/png;base64,', '')    
    io = FilelessIO.new(Base64.decode64(encoded_img))
    io.original_filename = "#{name}_#{rand(1000000)}.jpg"    
    return io 
  end
  
  def get_shipment
    shipment_id = params[:shipment_id]
	  render :status => 403, :json => {:errors => "Incorect shipment number"}.to_json and return if shipment_id == 0
	  @shipment = Shipment.api_search(shipment_id)
	  render :status => 404, :json => {:errors => "Shipment not found"}.to_json and return unless @shipment
  end
end
