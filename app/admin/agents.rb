ActiveAdmin.register Agent, :as => "Agents" do

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
