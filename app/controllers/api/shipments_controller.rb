class Api::ShipmentsController < Api::ApiController
  before_filter :get_shipment, :except => :mass_update 
  
  def show
    current_user.current_milestone.update_attributes :shipment_id => @shipment.id, :damaged => @shipment.damaged?#, :damage_desc => @shipment.damage_desc
    render :json => @shipment
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
