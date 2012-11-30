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
        @shipment.origin += params[:shipment][:origin_city] + ", " + params[:shipment][:origin_state]   + " " + params[:shipment][:origin_zip_postal_code] 

        @shipment.destination = params[:shipment][:dest_address1] 
        if params[:shipment][:dest_address2]
           @shipment.destination += "<br/>" + params[:shipment][:dest_address2] + "<br/>" 
        end 
        @shipment.destination += params[:shipment][:dest_city] +  ", " +  params[:shipment][:dest_state]  +  " "  +    params[:shipment][:dest_zip_postal_code] 

        #@shipment.ship_date = Date.strptime(params[:shipment][:ship_date], '%Y-%m-%d %H:%M:%S') rescue nil
        #@shipment.delivery_date = Date.strptime(params[:shipment][:delivery_date], '%Y-%m-%d %H:%M:%S') rescue nil   

        @shipment.ship_date = params[:shipment][:ship_date]
        @shipment.delivery_date = params[:shipment][:delivery_date]     

        if @shipment.save! 
           piece = Piece.find_by_sql ["SELECT SUM(weight) as weight, SUM(height) as height, SUM(length) as length, count(id) as pieces_total FROM pieces WHERE shipment_id = ? ",@shipment.id]
           if piece     
              piece = piece.first         
              #Update data of shipment table             
              @shipment.update_attributes(:weight => piece.weight, :height => piece.height, :length => piece.length, :pieces_total => piece.pieces_total )              
              @shipment.save!            
           end                           

        end
        render :json => {:status => 200, :message => t('messages.notice.milestone_created_ok')}
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
          milestone = shipment.milestones.create(shipment_data['milestone'])
          
          #Check setting
          setting = Setting.find_by_name('EnableWTUpdateStatus')
          if setting && setting.value == '1'
             #hawb = 340510 #For testing
             hawb = shipment.hawb
             #Call update status service from WordTrak
             client = Savon.client("http://freight.transpak.com/WTKServices/Shipments.asmx?WSDL")           
             response = client.request :update_status, body: {"HandlingStation" => "200", "HAWB" => hawb, "UserName" => "instatrace", "StatusCode" => "NEW"}

             if response.success?
               data = response.to_array(:update_status_response, :update_status_result).first      
               if data == true
                  puts "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
               else
                  puts "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
               end
             end 
          end  
          
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
