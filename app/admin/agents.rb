ActiveAdmin.register Agent, :as => "Agents" do
  action_item :only => :edit do
    link_to "Delete Agent", admin_agent_path ,:confirm => "Are you sure you want to delete this?", :method => :delete
  end
  
  # table for index action
  index do
    render :template => "/active_admin/agents/index"
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
        @agent.user_relations.build :user_id => params[:user][:user_id]
      end
    end

  end
  
  

  # form for new/edit actions
  form :partial => "/active_admin/agents/form"
end
