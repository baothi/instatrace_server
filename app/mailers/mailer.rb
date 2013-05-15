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
  	@shipment = milestone.shipment
  	subject = "Shimpent #{@shipment.shipment_id} was over, short or damaged"
  	operators = milestone.driver.user_relations.first.owner.users.operators.map &:email
    mail(:to => operators, :subject => subject)
    
    # send mail to agent, freight forwarder driver records a over, short or damaged
    agent = Agent.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Agent"', milestone.driver_id)
    if(agent[0])
      mail(:to => agent[0].email, :subject => subject) if agent[0].email
    end
    
    freightForwarder = Company.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Company"', milestone.driver_id)
    if(freightForwarder[0])
      mail(:to => freightForwarder[0].email, :subject => subject) if freightForwarder[0].email
    end
    
  end

  def send_milestone_signature(milestone)
    @milestone = milestone
    subject = "Milestone signature for shipment #{milestone.shipment.hawb}" 
    mail(:to => milestone.signature.email, :subject => subject) if milestone.signature.email
  end
end
