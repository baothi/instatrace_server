ActiveAdmin.register Milestone do
  actions :index, :edit, :update, :show

  filter :shipment, :as => :select, :collection => Shipment.select('id,hawb AS name').all
  filter :driver, :as => :select, :collection => User.drivers.select('id,email AS name').all
  filter :action
  filter :damage_desc
  filter :created_at
  filter :updated_at
  filter :location
  
  menu :if => proc{ can?(:read, Milestone) }
  controller.authorize_resource

  controller do
    #  Custome renders for xml and json formats
    def index
      respond_to do |format|
        format.csv { super }
        format.html { super }
        format.json { render :json => scoped_collection.to_json(:active_admin => true) }
        format.xml { render :partial => "/active_admin/milestones/index", :object => scoped_collection }
      end      
    end

    #  Redefine scoped_collection to include drivers
    def scoped_collection
      Milestone.includes(:driver)
    end
  end

  csv do
    column :shipment do |a|
      a.shipment.hawb if a.shipment
    end
    column :driver do |driver|
      driver.driver.email if driver.driver
    end
    column :action
    column :damaged
    column :public
    column :damage_desc
    column :created_at
  end
 
  # table for index action
  index do
    column :shipment do |a|
      link_to a.shipment.hawb, admin_shipment_path(a.shipment) if a.shipment
    end
    column 'Driver', :sortable => :'users.email' do |driver|
      link_to driver.driver.email, admin_user_path(driver.driver) if driver.driver
    end
    column :action
    column :damaged
    column :public
    column "Damage desription", :damage_desc
    column "Registered" do |mb|
        render :partial => "/active_admin/milestones/created_at" , :locals => { :created_at => mb.created_time_with_timezone }
    end
  end

  # table for show action
  show :title => "Milestone Details" do
    attributes_table :shipment, :driver, :action, :damaged, :damage_desc
    active_admin_comments
  end
  
  # form for new/edit actions
  form do |f|
    f.inputs "Milestone Details" do
      f.input :action, :as => :select, :collection => f.object.enums(:action).map{|a| [a.to_s.humanize, a]}, :include_blank => false
      f.input :damaged
      f.input :damage_desc
    end
    f.buttons
  end
end
