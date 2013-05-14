ActiveAdmin.register Setting do
  actions :index, :show, :update, :edit
  menu :if => proc{ current_user.sa? }
  controller.authorize_resource
  config.comments = false
  before_filter do @skip_sidebar = true end
  # menu false
  #config.clear_action_items!   # this will prevent the 'new button' showing up 
 
  index do        
    column("Setting Name") {|s| link_to s.name, admin_setting_path(s)}    
    column :value
    column :description  
  end

  form do |f|
    f.inputs do    
      #f.input :name
      f.input :value
      f.input :description      
    end
    f.buttons
  end
end
