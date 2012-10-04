class Api::LocationsController < Api::ApiController

  def create

    if location = Location.where(:driver_id => current_user).order("updated_at").first
      location.address = '-'
      location.update_attributes(params[:location])
      location.touch
    else
      location = current_user.locations.build(params[:location])
      location.address = '-'
    end

    if location.save
      render :status => 200, :nothing => true
    else
      render :status => 400, :json => {:errors => location.errors.full_messages}.to_json
    end
  end

end
