class ShipmentsController < ApplicationController
  layout Proc.new {|p| (%w(new create).include?(self.action_name)) ? 'popup' : 'application' }

  respond_to :json, :html, :js

  session :on
  # load_and_authorize_resource :except => :show
  
  def index
    @hawbs = Shipment.all.map &:hawb
    @shipments = Shipment.search(params[:shipment]).page(params[:page]).per(20)
    @search = Shipment.new(params[:shipment])
    cookies[:appversion] = application_version
    respond_with(@shipments) do |format|
      format.html
      format.json do 
        @shipments = @shipments.order("hawb #{params[:hawb_sort_by]}") if ['desc','asc'].include?(params[:hawb_sort_by].downcase)
        render :json => @shipments.to_json(addShip: true)
      end
    end
  end

  def show
    @shipment = Shipment.find_by_hawb(params[:id])
    redirect_to root_path, notice: "Shipment within HAWB #{params[:id].html_safe} was not found" unless @shipment
    # @shipment = Shipment.find(params[:id])
    # if (current_user && !current_user.sa? && (!current_user.allowed_shipments.include?(params[:id].to_i) || !session[:user_shipment_ids].include?(params[:id].to_i))) || 
    #   ((current_user.nil? && session[:user_shipment_ids].nil?) || (current_user.nil? && !session[:user_shipment_ids].include?(params[:id].to_i)))
    #   redirect_to shipments_path 
    # end
    # ids = session['user_shipment_ids']
    # redirect_to shipments_path, :notice => session['user_shipment_ids'].join(',') unless session['user_shipment_ids'].include?(params[:id].to_i)
  rescue
    redirect_to root_path
  end

  def new
    @shipment = Shipment.new
  end

  def create    
    @shipment = Shipment.new params[:shipment]
    @shipment.ship_date = Date.strptime(params[:shipment][:ship], '%m/%d/%Y') rescue nil
    @shipment.delivery_date = Date.strptime(params[:shipment][:delivery], '%m/%d/%Y') rescue nil
    respond_with(@shipment) do |format|
      format.js do
        render :update do |page|
          if @shipment.save
            page << "parent.$.fn.colorbox.close()"
            page.call 'notifyCreate', @shipment.to_json(:addShip => true)
          else
            page.call '$("#new_shipment_submit").button','reset'
            page.call "$('#shipment_new').replaceWith", render(:template => 'shipments/new')
          end          
        end
      end
    end    
  end

  def upload_edi
   	upload = params[:file_edi]
    if upload
     	parser = Parser.new(:data => upload.read)
     	unless parser.errors.any?
     		flash[:notice] = "<b>#{t('messages.upload_edi.header')}</b><p>#{t('messages.upload_edi.notice')}</p>"
     	else
     		flash[:error] = "<b>#{t('messages.upload_edi.header')}</b><p>#{parser.errors.map {|e| e[:full_message]}.join('<br />')}</p>" 
     	end
    else
      flash[:error] = "<b>#{t('messages.upload_edi.header')}</b><p>#{t('errors.messages.file_was_not_found')}</p>" 
    end
  	redirect_to shipments_path
  end

end
