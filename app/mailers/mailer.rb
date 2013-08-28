class Mailer < ActionMailer::Base
  default :from => "no-reply@instatrace.com"
  
  def user_created(user)
    @user, @pwd = user, user.password
    mail(:to => user.email, :subject => "Your account was registered at instatrace.com")   
  end

  def user_updated(user)
    @user, @pwd = user, user.password
    mail(:to => user.email, :subject => "Your account was updated at instatrace.com")   
  end

  def damage_notifier(milestone)
    @milestone = milestone
  	@shipment = milestone.shipment
  	subject = "Shimpent #{@shipment.shipment_id} has reported Over, Short or Damaged"
  	
  	# send mail to operator, agent, freight forwarder when driver records a over, short or damaged
  	recipients = milestone.driver.user_relations.first.owner.users.operators.map &:email

    agent = Agent.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Agent"', milestone.driver_id)
    recipients << agent[0].email if agent[0] && agent[0].email
    
    freightForwarder = Company.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Company"', milestone.driver_id)
    recipients << freightForwarder[0].email if freightForwarder[0] && freightForwarder[0].email
    
    mail(:to => recipients.join(','), :subject => subject)
  end
  
  def milestone_damaged_notifier(milestone)
    @milestone = milestone
    @shipment = milestone.shipment
    subject = "Shimpent #{milestone.shipment.hawb} has reported Over, Short or Damaged"
    
    recipients = Array.new
    agent = Agent.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Agent"', milestone.driver_id)
    recipients << agent[0].email if agent[0] && agent[0].email
    
    freightForwarder = Company.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Company"', milestone.driver_id)
    recipients << freightForwarder[0].email if freightForwarder[0] && freightForwarder[0].email
    
    # Send mail notify to Company which assigned to HAWB
    company = Company.first(:conditions =>["freight_forwarder_code =?", @shipment.freight_forwarder_code])
    recipients << company.email if company && company.email
    
    mail(:to => recipients.join(','), :subject => subject)

  end


  def send_milestone_signature(milestone)
    @milestone = milestone
    subject = "Milestone signature for shipment #{milestone.shipment.hawb}" 
    mail(:to => milestone.signature.email, :subject => subject) if milestone.signature.email
  end
  
  # Checking any new shipments was created in the last 24 hours by api/post_shipment. If none, send mail notify
  def post_shipment_notifier(shipment)
    @shipment = shipment
    subject = "WARNING: No InstaTrace Shipments Posted in 24 hours" 
    mail(:to => EMAIL_NOTIFY_POST_SHIPMENT_API, :subject => subject) if shipment.hawb && shipment.created_at
  end
end
