class SendBulkEmail
  # TODO: refactor even further
  # TODO: retire this method, as it's only in use once
  def self.call(emails, subject, template, locals, ccs = [])
    sent = 0
    emails.each do |email|
      email.strip!
      next unless email =~ /([^"<>\s]+@[^"<>\s]+)/
      validation_errors = ValidatesEmailFormatOf::validate_email_format($1)
##at silently ignore bad email addresses, be nice and inform the user
      #err_mess << validation_errors.join("\n")
      next if validation_errors

      AccountMailer.send_email(email, subject, template, locals, ccs).deliver_later

##at silently ignore the rest, be nice and tell the user
      break if (sent +=1) > 100
    end
  end
end
