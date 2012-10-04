ActiveAdmin.register Company do

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

  form :partial => "/active_admin/companies/form"
end
