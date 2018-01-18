class AccountMailer < ActionMailer::Base
  default from: '"HealthNotifier" <admin@domain.com>',
    return_path: 'app-bounces@domain.com'

  # GET yo style on
  layout 'email'
  
  def args_email_common(email, subject, message)
    {
      to:       email,
      subject:  subject
    }
  end

  def send_email(email, subject, template, context, ccs = [])
    # pre-render and then strip tags, like in django, omg
    html = render :template => template, :locals => context
    text = ActionController::Base.helpers.strip_tags(html)
    mail(:to => email, :subject => subject, cc: ccs) do |format|
      format.text { render text: text }
      format.html { html }
    end
  end

  # KILL
  def email_friend(email, subject, message)
    mail(args_email_common(email, subject, message))
  end

  # KILL
  def email_network_notice(email, subject, message)
    mail(args_email_common(email, subject, message))
  end

end
