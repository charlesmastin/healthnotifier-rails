class PostsmsscanNotificationJob < ApplicationJob
  queue_as :default

  def perform(scanner_phone_number, scanned_patient_id)
    credentials = nil
    geo = nil
    scanner = nil
    scanner_account = nil

    #query AR son
    scanned_patient = Patient.where(:patient_id => scanned_patient_id).first

    emails_notified = []
    phones_notified = []

    sms_body = "Your LifeSticker (#{scanned_patient.first_name}) was scanned by #{scanner_phone_number}." 
    # notify all the other peoples bro

    # TODO: attempt to tie the phone number to an account on file, not going to work well, considering we don't enforce a unique constraint on mobile yet??

    twilio_client = Twilio::REST::Client.new(
      Rails.configuration.twilio[:account_sid],
      Rails.configuration.twilio[:auth_token]
    )

    # query the caller details, costs per request
    scanner_name = PhoneValidator.call_callerid(scanner_phone_number)

    ###########################################################################
    #### NOTIFY OWNER
    ###########################################################################

    # PUSH
    notified = SNSNotification.postscansms(scanned_patient.account.this_is_me_maybe, sms_body, scanned_patient, scanner_phone_number, scanner_name)
    # push is just a value add, even if the UX doesn't offer it
    # we know it can be A. hard to interact with, B. dismissed, C. etc
    # SEND SMS anyhow, an acceptable double hit chen but sure to be in your face!

    if scanned_patient.account.mobile_phone != nil
      # TODO: RESTORE THE TEMPLATE OMG SON
      #view = ActionView::Base.new(ActionController::Base.view_paths, context, ActionController::Base.new)
      #sms_body = view.render(file: 'patient_network/sms/scan_notification.erb')
      # YES I HATE MYSELF
      phonenum = scanned_patient.account.mobile_phone.gsub(/\D/, '')

      # TODO: this is unecessary
      # scrub the number down with the lookup API just to be damn sure?
      scrubbed_number = "+1#{phonenum}"
      number = PhoneValidator.call(phonenum)
      if number != nil
        # look at the details, meh meh, probably should roll this bit into the service but whatevs
        if number.carrier['type'] == 'mobile'
          scrubbed_number = number.phone_number
        end
      end

      # sms_body = render :template => 'patient_network/sms/scan_notification', :locals => context
      begin
        message = twilio_client.account.messages.create(:body => sms_body,
          :to => scrubbed_number,
          :from => Rails.configuration.twilio[:phone_number])
        # strip it down
        # phones_notified.push(scrubbed_number)
      rescue Twilio::REST::RequestError => e
        # TODO: log somewhere
        # raise
      end
    end

    ###########################################################################
    #### NOTIFY PATIENT NETWORK
    ###########################################################################

    sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner_phone_number}."
    if scanner_name
      sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner_phone_number} w/ callerid of #{scanner_name}."
    end

    connections = PatientNetwork.where(:granter_patient_id => scanned_patient.patient_id, :notification_postscan => true)
    connections.each do |connection|
      if connection.auditor_patient.account != scanner_account
        # TODO: ensure there is some connection level in here
        # if ['public', 'provider', 'private'].include? connection.privacy
        context = {
          :connection => connection,
          :patient => scanned_patient,
          :scanner => scanner,
          :scanner_phone_number => scanner_phone_number,
          :scanner_name => scanner_name,
          :credentials => credentials, # could be nil
          :scantime => Time.now,
          :geo => geo # could be nil
        }

        # PUSH first
        notified = SNSNotification.postscansms(connection.auditor_patient, sms_body, scanned_patient, scanner_phone_number, scanner_name)
        # SMS only if no PUSH
        if notified == 0
          # fallback SMS, etc, etc, etc, etc
          if connection.auditor_patient.account.mobile_phone != nil
            # TODO: RESTORE THE TEMPLATE OMG SON
            #view = ActionView::Base.new(ActionController::Base.view_paths, context, ActionController::Base.new)
            #sms_body = view.render(file: 'patient_network/sms/scan_notification.erb')
            # YES I HATE MYSELF
            phonenum = connection.auditor_patient.account.mobile_phone.gsub(/\D/, '')

            # scrub the number down with the lookup API just to be damn sure?
            scrubbed_number = "+1#{phonenum}"
            number = PhoneValidator.call(phonenum)
            if number != nil
              # look at the details, meh meh, probably should roll this bit into the service but whatevs
              if number.carrier['type'] == 'mobile'
                scrubbed_number = number.phone_number
              end
            end

            # sms_body = render :template => 'patient_network/sms/scan_notification', :locals => context
            begin
              message = twilio_client.account.messages.create(:body => sms_body,
                :to => scrubbed_number,
                :from => Rails.configuration.twilio[:phone_number])
              # strip it down
              phones_notified.push(scrubbed_number)
            rescue Twilio::REST::RequestError => e
              # TODO: log somewhere
              # raise
            end

          end
        end

        # EMAIL always
        begin
          AccountMailer.send_email(
            connection.auditor_patient.account.email,
            "#{scanned_patient.first_name}’s LifeSticker was scanned",
            'patient_network/mailer/scan_notification',
            context
          ).deliver_now
          emails_notified.push(connection.auditor_patient.account.email.downcase)
        rescue
          # TODO: log somewhere
          # raise
        end
      end
    end

    ###########################################################################
    #### NOTIFY EMERGENCY CONTACTS
    ###########################################################################

    # if scanner_phone_number is on file for account, hmm, not sure what we do though, like no reason to test it
    # ugg ugg ugg this is going to require opt-in ASAP BRO

    sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner_phone_number}. You are listed as an emergency contact."

    emergency_contacts = PatientContact.nonself_by_patient_id(scanned_patient.patient_id).where(:notification_postscan => true)
    emergency_contacts.each do |contact|
      context = {
        :contact => contact, # for personalization hooks??
        :patient => scanned_patient,
        :scanner => scanner,
        :scanner_phone_number => scanner_phone_number,
        :scanner_name => scanner_name,
        :scantime => Time.now,
        :geo => nil
      }

      # this is ghetto, the UI stopped labelling a long time again, so we're not sure it will actually be a mobile phone
      # however the UI copies the data into the mobile phone column
      if contact.home_phone
        phonenum = contact.home_phone.gsub(/\D/, '')
        # scrub the number down with the lookup API just to be damn sure?
        scrubbed_number = "+1#{phonenum}"
        number = PhoneValidator.call(phonenum)
        if number != nil
          # look at the details, meh meh, probably should roll this bit into the service but whatevs
          if number.carrier['type'] == 'mobile'
            scrubbed_number = number.phone_number
          end
        end
        begin
          message = twilio_client.account.messages.create(:body => sms_body,
            :to => scrubbed_number,
            :from => Rails.configuration.twilio[:phone_number])
        rescue Twilio::REST::RequestError => e
          # TODO: log somewhere
          # raise
        end
      end

      if contact.email
        begin
          AccountMailer.send_email(
            contact.email,
            "#{scanned_patient.first_name}’s LifeSticker was scanned",
            'patient_network/mailer/scan_notification',
            context
          ).deliver_now
        rescue
          # TODO: log somewhere
          # raise
        end
      end

    end

    ###########################################################################
    #### SMS PHOTO TO SCANNER (could move back to controller or separate job though)
    ###########################################################################

    # send the mms photo w/ media_url at this point since we can't effectively queue anything
    # uggg
    if scanned_patient.photo_uid
      begin
        message = twilio_client.account.messages.create(
          :body => "Photo for identification of #{scanned_patient.first_name}.",
          :media_url => "#{Rails.application.routes.url_helpers.api_patient_photo_url(scanned_patient.uuid)}?photo_uuid=#{scanned_patient.photo_uid}&width=800&height=800",
          :to => scanner_phone_number,
          :from => Rails.configuration.twilio[:phone_number])
      rescue Twilio::REST::RequestError => e
        # raise e
        # TODO: log somewhere
      end
    end
  end

end