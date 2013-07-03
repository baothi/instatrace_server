require 'net/ftp'

class Api::ShipmentsController < Api::ApiController
  before_filter :get_shipment, :except => [:mass_update ,:post_shipment]
  include ActionView::Helpers
  
  def show
    current_user.current_milestone.update_attributes :shipment_id => @shipment.id, :damaged => @shipment.damaged?#, :damage_desc => @shipment.damage_desc
    render :json => @shipment
  end
  # @API Create or update shipment data
  # @route
  # => post '/shipment/post_shipment'
  # @argument : JSON
  # => params["shipment"]["hawb"]                   : Shipment HAWB code string
  # => params["shipment"]["pieces"]                 : Array dimention weight/length/height for each pieces
  # => params["shipment"]["origin_address1"]        : From address1 string
  # => params["shipment"]["origin_address2"]        : From address2 string
  # => params["shipment"]["origin_city"]            : From address city string
  # => params["shipment"]["origin_state"]           : From address state string
  # => params["shipment"]["origin_zip_postal_code"] : From address post zip code string
  # => params["shipment"]["origin_country"]         : From address country code string
  # => params["shipment"]["dest_address1"]          : Destination address1 string
  # => params["shipment"]["dest_address2"]          : Destination address2 string
  # => params["shipment"]["dest_city"]              : Destination address city string
  # => params["shipment"]["dest_state"]             : Destination address state string
  # => params["shipment"]["dest_zip_postal_code"]   : Destination address post zip code string
  # => params["shipment"]["dest_country"]           : Destination address country code string
  # => params["shipment"]["shipper"]                : Shipper name
  # => params["shipment"]["ship_date"]              : Ship date
  # => params["shipment"]["delivery_date"]          : Delivery date
  # => params["shipment"]["consignee"]              : Consignee name
  # => params["shipment"]["service_level_code"]     : Service level code string
  # => params["shipment"]["service_level"]          : String days service
  # => params["shipment"]["pick_up_and_delivery_instructions"]: Pick up and deliver instruction code string
  # => params["shipment"]["shipment_types"]         : Shipment type code string
  # => params["shipment"]["mawb"]                   : Shipment MAWB code string
  # => params["shipment"]["carrier_scac_code"]      : Carrier SCAC code string
  # => params["shipment"]["receiver_scac_code"]     : Receiver SCAC code string
  # => params["shipment"]["piece_count"]            : Piece count number
  # => params["shipment"]["special_instructions"]   : Special instructions
  # => params["shipment"]["dangerous_goods"]        : If true, value is "1"
  # @return : JSON
  # => status : Status code (error: 400, success: 200)
  # => message: Message string
  def post_shipment
    begin
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
               @shipment.is_post_shipment = 1
            end
            
            @shipment.origin =  params[:shipment][:origin_address1] + "<br>"
            if params[:shipment][:origin_address2] && !params[:shipment][:origin_address2].nil?
               @shipment.origin += params[:shipment][:origin_address2] + "<br>"
            end   
            origin_country_name = COUNTRY_CODE['countrycode'][params[:shipment][:origin_country]] 
            @shipment.origin += params[:shipment][:origin_city] + ", " + params[:shipment][:origin_state]   + " " + params[:shipment][:origin_zip_postal_code]  + "  " + origin_country_name
            
            @shipment.origin_address1 = params[:shipment][:origin_address1]
            @shipment.origin_address2 = params[:shipment][:origin_address2]
            @shipment.origin_city = params[:shipment][:origin_city]
            @shipment.origin_state = params[:shipment][:origin_state]
            @shipment.origin_zip_postal_code = params[:shipment][:origin_zip_postal_code]
            @shipment.origin_country = params[:shipment][:origin_country]
            
            @shipment.destination = params[:shipment][:dest_address1] + "<br>"
            
            if params[:shipment][:dest_address2] && !params[:shipment][:dest_address2].nil?
              @shipment.destination += params[:shipment][:dest_address2] + "<br>"
            end
            
            dest_country_name = COUNTRY_CODE['countrycode'][params[:shipment][:dest_country]] 
            
            @shipment.destination += params[:shipment][:dest_city] +  ", " +  params[:shipment][:dest_state]  +  " "  +    params[:shipment][:dest_zip_postal_code]  + "  "  + dest_country_name
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
                
                #***********************************************************
                #********* Send FSA request to Descartes FTP server ********
                #***********************************************************
                puts "********* Send FSA request to Descartes FTP server : HAWB = #{@shipment.hawb}, MAWB = #{@shipment.mawb} ********"
                receiver_id = @shipment.mawb[0..2]
                real_mawb = @shipment.mawb[3..-1]
                iata = DESCARTES_CARRIER['carrier'][receiver_id]
                # MAWB code must be 11 characters 
                # 3 characters is air carrier code which is mapped with IATA code in file descartes.yml
                # 8 next characters for real MAWB
                if @shipment.mawb.length != 11 || iata.nil? 
                   puts "**********************Invalid MAWB****************"
                else
                   begin
                       fsr_file = File.join(Rails.root, "tmpfile","descartes", "FSR.txt")
                       
                       if File.exists?(fsr_file)
                           File.delete
                           puts "**********************Delete old file if existing****************"        
                       end
                       fsr_timestamp = Time.now
                       day = fsr_timestamp.day < 10 ? '0' + fsr_timestamp.day.to_s : fsr_timestamp.day.to_s
                       hour = fsr_timestamp.hour < 10 ? '0' + fsr_timestamp.hour.to_s : fsr_timestamp.hour.to_s
                       min = fsr_timestamp.min < 10 ? '0' + fsr_timestamp.min.to_s : fsr_timestamp.min.to_s
                       
                       File.open(fsr_file,"w+") do |f|
                           f.write("QK #{iata}\n")
                           f.write(".SFOTRPA #{day}#{hour}#{min}\n")
                           f.write("FSR\n")
                           f.write("#{receiver_id}-#{real_mawb}\n")
                       end
                       
                       #Get FTP server detail
                       descartes_config = COMMON['config']['ftp']['descartes']
                       # Create file and send file to FTP server
                       ftp = Net::FTP::new(descartes_config["host"])
                       if ftp.login(descartes_config["username"], descartes_config["password"])
                           ftp.passive = true
                           ftp.puttextfile(fsr_file,"FSR.txt")
                       end
                       # End create file and send file to FTP server
                       ftp.close
                       Rails.logger.info "*****************SEND FSR SUCCESS for Shipemt with HAWB: #{@shipment.hawb}, time: #{fsr_timestamp}"
                   rescue Exception => e
                       puts "********************* Send request FSR to Descartes FTP server error **************"
                       puts "#{e.message}"
                   end
                end
                #End check valid MAWB code
                puts "******* End send FSA request to Descartes FTP server ******"
                #***********************************************************
                #******* End send FSA request to Descartes FTP server ******
                #***********************************************************
                
                message = 'Shipment was successfully updated.'
                render :json => {:status => 200, :message => message}
            else
                render :json => {:status => 400, :message => message}
            end
        else
            #Invalid JSON data post
            #raise Exception, t('errors.messages.not_found')
            logger = Logger.new("#{Rails.root}/log/api_errors.log", 1, 100 * 1024 * 1024)
            logger.info "                             "
            logger.info "# Logfile created on #{Time.now}"
            logger.info "*****************ERROR POST Shipment"
            logger.info "*****************data post :"
            logger.info "#{params.inspect}"
            
            render :json => {:status => 400, :message => t('errors.messages.not_found')}
        end
    rescue Exception => e  
        Rails.logger.info "*****************ERROR POST Shipment"
        Rails.logger.info "*****************data post :"
        Rails.logger.info "#{params.inspect}"
        Rails.logger.info "*****************error message :"
        Rails.logger.info "#{e.message}"
        Rails.logger.info "*****************error backtrace :"
        Rails.logger.info "#{e.backtrace.inspect}"
        Rails.logger.info "********************************************************************"
        
        # Store Log in api_errors.log
        logger = Logger.new("#{Rails.root}/log/api_errors.log", 1, 100 * 1024 * 1024)
        logger.info "                             "
        logger.info "# Logfile created on #{Time.now}"
        logger.info "*****************ERROR POST Shipment"
        logger.info "*****************data post :"
        logger.info "#{params.inspect}"
        logger.info "*****************error message :"
        logger.info "#{e.message}"
        logger.info "*****************error backtrace :"
        logger.info "#{e.backtrace.inspect}"
        logger.info "********************************************************************"
        
        render :json => {:status => 400, :message => e.message}
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
          
          # Params for checking send mail notify to Agent and 
          if shipment_data['milestone']['damaged'] && shipment_data['milestone']['damaged'] == 1
            shipment_data['milestone']['damaged_notifier'] = 1
          else
            shipment_data['milestone']['damaged_notifier'] = ""
          end
          
          agent = Agent.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Agent"', @user.id)
          if(agent[0])
            shipment_data['milestone']['agent_id'] = agent[0].id
          else 
            shipment_data['milestone']['agent_id'] = ""
          end
          
          action_code = ''
          #Set action_code for new milestone
          if shipment_data["milestone"]["action"]     
           #action_code = TRANSPAK['AT7'].select {|k,v| v == shipment_data["milestone"]["action"]} 
           action_code = TRANSPAK['AT7'].key(shipment_data["milestone"]["action"])
           
           shipment_data["milestone"]["action_code"] = action_code               
          end 
          
          milestone = shipment.milestones.create(shipment_data['milestone'])
          
          #Params store base64 encode images data of POD image and signature image for Transpak service UploadPODDocument 
          document_encoded_img = nil
          signature_encoded_img = nil
          
          if  shipment_data['document']
            document = milestone.milestone_documents.build(:doc_type => shipment_data['document']['doc_type'])
            document.name = create_image(shipment_data['document']['name'],'document')
            document.save
            
            # Base64 encode POD image ready for Transpak service UploadPODDocument
            document_encoded_img = shipment_data['document']['name'].sub('data:image/bmp;base64,', '').sub('data:image/png;base64,', '')
          end
          
          if shipment_data['signature']
            sign = milestone.create_signature(:name      => shipment_data['signature']['name'],
                                              :email     => shipment_data['signature']['email'],
                                              :signature => create_image(shipment_data['signature']['signature'],'signature'))
            
            # Base64 encode signature image ready for Transpak service UploadPODDocument
            signature_encoded_img = shipment_data['signature']['signature'].sub('data:image/bmp;base64,', '').sub('data:image/png;base64,', '')
          end
          
          unless shipment_data['damage_photo'].nil? || shipment_data['damage_photo'].empty?
            shipment_data['damage_photo'].each do |image|
              milestone.damages.create(:photo => create_image(image,"damage"))
            end
          end
          
          #Check setting
          setting = Setting.find_by_name('EnableWTUpdateStatus')
          
          if setting && setting.value == '1'
             hawb = shipment.hawb  
             piece_count = shipment.piece_count
             
             #Call update status service from WordTrak             
             begin
                client = Savon.client("http://freight.transpak.com/WTKServices/Shipments.asmx?WSDL")
                response = client.request :update_status, body: {"HandlingStation" => "", "HAWB" => hawb, "UserName" => "instatrace", "StatusCode" => action_code}
                if response.success?
                   data = response.to_array(:update_status_response).first[:update_status_result]
                   
                   if data == true
                      Rails.logger.info "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                   else
                      Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                   end
                end
                 
                if milestone && milestone.action.to_s == 'delivered'
                    login_name = nil
                    signature_name = nil
                    delivered_date = nil
                    if milestone && milestone.signature
                       login_name = milestone.driver.login
                       signature_name = milestone.signature.name
                       zone = RestClient.get("http://api.geonames.org/timezone?lat=#{milestone.latitude}&lng=#{milestone.longitude}&username=instatrace")
                       timezone = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
                       delivered_date = milestone.created_at.in_time_zone(timezone).to_s('YYYY-MM-DD HH:MM:SS')
                    end
                    
                    #Call SubmitPOD service from WordTrak  
                    response = client.request :submit_pod, body: {"UserInitials" => "US", "HAWB" => hawb, "UserName" => login_name, "PiecesDelivered" => piece_count.to_i, "Signer" => signature_name, "PODDateTime" => delivered_date} 
                    
                    if response.success?
                       data = response.to_array(:submit_pod_response).first[:submit_pod_result]
                       if data == true
                          Rails.logger.info "*****************SUCCESS SubmitPOD Wordtrak!  for Shipment with HAWB: #{hawb}"
                       else
                          Rails.logger.info "*****************ERROR SubmitPOD Wordtrak!  for Shipment with HAWB: #{hawb}"
                       end
                    end
                   
                    #Call UploadPODDocument service from WordTrak to upload signature image
                    if ! signature_encoded_img.nil?
                        response = client.request :upload_pod_document, body: {"HAWB" => hawb, "DocumentDataBase64" => signature_encoded_img, "DocumentExtension" => "signature.jpg"} 
                        
                        if response.success?
                           data = response.to_array(:upload_pod_document_response).first[:upload_pod_document_result]
                           if data == true
                              Rails.logger.info "*****************SUCCESS UploadPODDocument Wordtrak!  for Shipment upload signature image with HAWB: #{hawb}"
                           else
                              Rails.logger.info "*****************ERROR UploadPODDocument Wordtrak!  for Shipment upload signature image with HAWB: #{hawb}"
                           end
                        end
                    end
                    #End call UploadPODDocument service from WordTrak to upload signature image
                    
                    #Call UploadPODDocument service from WordTrak to upload POD image
                    if ! document_encoded_img.nil?
                        response = client.request :upload_pod_document, body: {"HAWB" => hawb, "DocumentDataBase64" => document_encoded_img, "DocumentExtension" => "jpg"} 
                        
                        if response.success?
                           data = response.to_array(:upload_pod_document_response).first[:upload_pod_document_result]
                           if data == true
                              Rails.logger.info "*****************SUCCESS UploadPODDocument Wordtrak!  for Shipment upload POD image with HAWB: #{hawb}"
                           else
                              Rails.logger.info "*****************ERROR UploadPODDocument Wordtrak!  for Shipment upload POD image with HAWB: #{hawb}"
                           end
                        end
                    end
                    #End call UploadPODDocument service from WordTrak to upload POD image
                end
             rescue Savon::Error => error
                  Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb} #{error}"
             end
          end
        end
      end #End rollback
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
