class PostscanNotificationJob < ApplicationJob
  queue_as :default

  def perform(scanner_account_id, scanned_patient_id, latitude=nil, longitude=nil)
    # TODO: scanning patient context
    network_connection = nil
    credentials = nil
    geo = nil
    scanner = nil

    # AR query all the things brosef
    scanner_account = Account.where(:account_id => scanner_account_id).first
    scanned_patient = Patient.where(:patient_id => scanned_patient_id).first

    twilio_client = Twilio::REST::Client.new(
      Rails.configuration.twilio[:account_sid],
      Rails.configuration.twilio[:auth_token]
    )

    # if network_connection_id
    #   network_connection = PatientNetwork.where()
    #   scanner = network_connection.auditor_patient
    # else
    #   scanner = scanner_account.this_is_me_maybe
    # end
    scanner = scanner_account.this_is_me_maybe

    # TODO: include contact number of scanner for doing callback
    scanner_callback = ""
    if scanner.account.mobile_phone != nil
      scanner_callback = " #{scanner.account.mobile_phone}"
    end

    if scanner_account.provider?

      # find the credentials, not sure how to get right now, so let's skip that detail
      # this is sloppy, need a central way to query this on the user since we should NEVER have more than one patient "be" the provider identity on an account
      # leave some wiggle room since we "may" have rando edge cases where there are no creds on file
      if network_connection
        credentials = ProviderCredential.where(:patient_id => network_connection.auditor_patient.patient_id, :credentialed => true, :status => 'ACCEPTED').order('created_at').first
      else
        # I know this may fail, short on time atm
        # TODO: actually find the provider patient for this account, this is a guess and could result in the wrong name shown
        credentials = ProviderCredential.where(:patient_id => scanner_account.this_is_me_maybe.patient_id, :credentialed => true, :status => 'ACCEPTED').order('created_at').first
      end
    else
      # else, maybe we do something, not yet though
    end

    # TODO: get a list of emergency contacts, and ensure we don't double hit them, if they, by the off chance are actually also in the LifeCircle
    # reminds me of the business logic for what happens when an emergency contact is IN-NETWORK
    # or the UX for selecting said thingy… that said, probably a rarity

    # TODO: do the geocoding
    if latitude && longitude
      results = Geocoder.search("#{latitude},#{longitude}")
      # TODO: scrub this down for specificity, for now, just let the template deal with it… LOL YIKES SON
      if results.length > 0
        geo = results[0]
      end
    end

    # OWNER notification push + SMS (aka your managed/directly controlled lifesquares, eg. children)

    # this is the generic non-personalized version here!
    # TODO: return phone call, for the sns, needs to be category and include more meta data

    if geo
      sms_body = "Your LifeSticker (#{scanned_patient.first_name}) was scanned by #{scanner.name_extended}#{scanner_callback} near the location: #{geo.formatted_address}"
    else
      sms_body = "Your LifeSticker (#{scanned_patient.first_name}) was scanned by #{scanner.name_extended}#{scanner_callback}." 
    end

    # track who has been sent things, so we can send emergency contacts a single copy only if they area coincidentally in the network
    emails_notified = []
    phones_notified = []

    ###########################################################################
    #### NOTIFY OWNER
    ###########################################################################

    # notify lifesquare.account device - TODO: dry up the entire notification stack bro
    # slightly different rendering context bro
    # TODO: return phone call, for the sns, needs to be category and include more meta data
    notified = SNSNotification.postscan(scanned_patient.account.this_is_me_maybe, sms_body, scanned_patient, scanner_account.mobile_phone, latitude, longitude, geo)
    # SMS fallback brizzle
    if scanned_patient.account.mobile_phone != nil
      # TODO: RESTORE THE TEMPLATE OMG SON
      #view = ActionView::Base.new(ActionController::Base.view_paths, context, ActionController::Base.new)
      #sms_body = view.render(file: 'patient_network/sms/scan_notification.erb')
      # YES I HATE MYSELF
      phonenum = scanned_patient.account.mobile_phone.gsub(/\D/, '')

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

    ###########################################################################
    #### NOTIFY PATIENT NETWORK
    ###########################################################################

    if geo
      sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner.name_extended}#{scanner_callback} near the location: #{geo.formatted_address}"
    else
      sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner.name_extended}#{scanner_callback}." 
    end

    connections = PatientNetwork.where(:granter_patient_id => scanned_patient.patient_id, :notification_postscan => true)
    connections.each do |connection|
      # Don't send to self if the scanner, lul
      if connection.auditor_patient.account != scanner_account
        # TODO: ensure this works
        # if ['public', 'provider', 'private'].include? connection.privacy

        context = {
          :connection => connection,
          :patient => scanned_patient,
          :scanner => scanner,
          :credentials => credentials, # could be nil
          :scantime => Time.now,
          :geo => geo,
          :latitude => latitude,
          :longitude => longitude
        }

        # PUSH
        notified = SNSNotification.postscan(connection.auditor_patient, sms_body, scanned_patient, scanner_account.mobile_phone, latitude, longitude, geo)
        
        # SMS fallback
        if notified == 0
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

        # EMAIL
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

    # this is the generic non-personalized emergency contact version here!
    if geo
      sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner.name_extended}#{scanner_callback} near the location: #{geo.formatted_address}. You are listed as an emergency contact."
    else
      sms_body = "The LifeSticker for #{scanned_patient.name_extended} was scanned by #{scanner.name_extended}#{scanner_callback}. You are listed as an emergency contact."
    end

    # TODO: consider product issue around this
    emergency_contacts = PatientContact.nonself_by_patient_id(scanned_patient.patient_id).where(:notification_postscan => true)
    emergency_contacts.each do |contact|
      context = {
        :contact => contact, # for personalization hooks??
        :patient => scanned_patient,
        :scanner => scanner,
        :credentials => credentials, # could be nil
        :scantime => Time.now,
        :geo => geo,
        :latitude => latitude,
        :longitude => longitude
      }

      # and !emails_notified.include? contact.email.downcase
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
          raise
        end
      end

      # this is ghetto, the UI stopped labelling a long time again, so we're not sure it will actually be a mobile phone
      # however the UI copies the data into the mobile phone column
      # TODO: and !phones_notified.include? contact.home_phone.gsub(/\D/, '') won't reliably work now
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
    end
  end

end