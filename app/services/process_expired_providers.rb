class ProcessExpiredProviders
  # TODO: THIS IS RAM CODE, CHECK IT STILL WORKS, OMG
  def self.call
    puts "#======================================="
    puts "# Processing expired providers for today: #{Date.today}"
    puts "#---------------------------------------"
    ProviderCredential.all.each do |provcred|
      loginfo = "..Provider #{provcred.patient.fullname}"\
                ": current status #{provcred.status}"
      if !(provcred.past_expiration?)
        loginfo += ", will not expire until #{provcred.expiration}"
      elsif (provcred.expired? || provcred.rejected?)
        loginfo += ", already expired on #{provcred.expiration}"
      else
        loginfo += ", is NOW PAST ITS EXPIRATION on #{provcred.expiration}"
        provcred.expired! 
        provcred.save!

        # send support staff notifications so we can do something
        email = Rails.application.config.default_admin_email
        subject = "Provider Credentials Expired"
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          AccountMailer.send_email(email, subject, 'provider/mailer/support_notification_expiration', {:provider_credential => provcred }).deliver_now
        end

        # send the patient a notification so they are aware
        email = provcred.patient.account.email
        subject = "Lifesquare Provider Credentials Expired"
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          AccountMailer.send_email(email, subject, 'provider/mailer/account_notification_expiration', {:provider_credential => provcred }).deliver_now
        end

        loginfo += "; status changed to #{provcred.status}"
      end
      puts loginfo + "."
    end
    puts "#---------------------------------------"
  end
end
