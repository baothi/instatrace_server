ActiveAdmin.register Company do
  action_item :only => :edit do
    link_to "Delete Company", admin_company_path ,:confirm => "Are you sure you want to delete this?", :method => :delete
  end
  
  controller do
    def create
      super
      create_user_relations
    end    

    def update
      super
      create_user_relations
    end

    def create_user_relations
      if params[:user] && params[:user][:user_id]
        @company.user_relations.build :user_id => params[:user][:user_id]
      end
    end

  end
  
  # table for index action
  index do
    render :template => "/active_admin/companies/index"
  end
  
  form :partial => "/active_admin/companies/form"
end
