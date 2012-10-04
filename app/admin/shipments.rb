ActiveAdmin.register Shipment do

  menu :if => proc{ can?(:update, Shipment) }
  controller.authorize_resource

  # table for index action
  index do
    column(:hawb) {|s| link_to s.hawb, admin_shipment_path(s)}
    column :service_level
    column :mawb
    column :pieces
    column("Weight") {|s| "#{number_with_delimiter(s.weight.to_i)} Lb." }
    column :origin
    column :destination
    column :shipper
    column :consignee
    column :ship
    column :delivery
    column "Registered", :created_at
  end

  # table for show action
  show :title => :shipment_id do |s|
    attributes_table do
      row :shipment_id
      row :service_level
      row :hawb
      row :mawb
      row :pieces
      row (:weight) { "#{number_with_delimiter(s.weight.to_i)} Lb." }
      row :origin
      row :destination
      row :shipper
      row :consignee
      row :ship
      row :delivery
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
      f.input :pieces
      f.input :weight
      f.input :origin
      f.input :destination
      f.input :shipper
      f.input :consignee
      f.input :ship
      f.input :delivery
    end
    f.buttons
  end
end

