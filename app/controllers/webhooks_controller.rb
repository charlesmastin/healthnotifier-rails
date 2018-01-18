require 'twilio-ruby'

class WebhooksController < ApplicationController
  # protect_from_forgery :except => :stripe # TODO: is this deprecated syntax with the whole filter action business?

  def stripe
    if params['type'] == 'invoice.payment_succeeded'
      # find the correlating subscription on our side
      begin
        if params['data']['object']['subscription']
          coverage = Coverage.where(:coverage_status => 'ACTIVE', :stripe_subscription_key => params['data']['object']['subscription']).first
          if coverage
            # check our dates and stuff, is this the renewal payment... if so, create a new coverage object, and send a renewal email
            if (coverage.coverage_start - Date.today).to_i.abs <= 1
              # we are the coverage that just started, what what what!
              render json: '{ "success": true, "message": "Awesome Sauce" }', status: 200
              return
            end
            # are we on the same day as we started... or within a certain time, allowing for timezone differences and stuff

            # create a payment object, son

            # look up that new charge to store it up
            stripe_charge = Stripe::Charge.retrieve(params['data']['object']['charge'])

            payment = Payment.new
            payment.account_id = coverage.patient.account.account_id
            payment.patient_id = coverage.patient.id
            payment.description = 'Annual Coverage For %s. Expires %s' % [coverage.patient.fullname, Date.today + 365],
            payment.category = 'coverage'
            payment.amount = params['data']['object']['total']
            payment.processor = 'stripe'
            payment.processor_payment_id = params['data']['object']['charge']
            payment.processor_response = stripe_charge.to_json
            payment.save

            new_coverage = Coverage.new
            new_coverage.patient = coverage.patient
            new_coverage.coverage_start = Date.today
            new_coverage.coverage_end = Date.today + 365
            new_coverage.payment = payment
            new_coverage.recurring = true
            new_coverage.stripe_subscription_key = coverage.stripe_subscription_key
            new_coverage.coverage_status = 'ACTIVE'
            new_coverage.save

            coverage.coverage_status = 'INACTIVE'
            coverage.save

            # then update charge meta data, son
            stripe_charge.metadata['coverage_id'] = coverage.coverage_id
            stripe_charge.metadata['patient_id'] = coverage.patient.id
            stripe_charge.metadata['account_id'] = coverage.patient.account.account_id
            stripe_charge.metadata['account_email'] = coverage.patient.account.email
            stripe_charge.save

            # then we be done
            email = coverage.patient.account.email
            if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
              AccountMailer.send_email(email, 
                "Coverage renewed",
                'patients/mailer/coverage_receipt',
                {
                  :coverage => new_coverage,
                  :renewal => true
                }).deliver_later
            end



          end

        end
      rescue

      end

      # if we match

      # send an email to the user saying it was dope
      render json: '{ "success": true, "message": "Awesome Sauce" }', status: 200
    end

    if params['type'] == 'invoice.payment_failed'
      # should be in regards to failed subscription
      if params['data']['object']['subscription']
        coverage = Coverage.where(:coverage_status => 'ACTIVE', :stripe_subscription_key => params['data']['object']['subscription']).first
        if coverage
          # send admins an email,
          email = 'admin@domain.com'
          AccountMailer.send_email(email, 
            "Subscription failed",
            'patients/mailer/subscription_failed_admin',
            {
              :coverage => coverage
            }).deliver_later


          # send patient an email,
          email = coverage.patient.account.email
          if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
            AccountMailer.send_email(email, 
              "Billing error",
              'patients/mailer/subscription_failed',
              {
                :coverage => coverage
              }).deliver_later
          end
        end
      end

      render json: '{ "success": true, "message": "Awesome Sauce" }', status: 200

    end
  end

  # TODO: uncertain of if we only use the shortcode, or have discreet numbers, for outbound helpful bits, and for "scanning"

  # twilio bits here
  def twilio_voice
    # default handler for people calling in
    render json: {
      :success => false,
      :message => "No logic found, defaults to Twilio error handler with Alice voice"
    }, status: 404
    return
  end
  #
  def twilio_sms
    # since it's not a json api, blablabla
    # this is gonna be the short code, maybe a different number
    body = params['Body'].upcase

    # look for all the action keywords, and so on and so forth

    # TODO: insert consent and legal bits n bobs

    # if nothing found, assume scanning
    code = body.split(' ').join('')

    ls = Lifesquare.where(:lifesquare_uid => code).first

    if ls == nil
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message "Please enter the 9-character Customer ID to see vitals and emergency contacts."
      end
      render :xml => twiml.text
      return
    end

    patient = Patient.where(:patient_id => ls.patient_id, :confirmed => true, :status => 'ACTIVE').first
    if patient == nil
      twiml = Twilio::TwiML::Response.new do |r|
        r.Message "No cutomer found"
      end
      render :xml => twiml.text
      return
    end

    # permission defaults
    privacy_level = 'public'
    is_owner = false
    is_provider = false
    sound_the_alarm = false

    # is the incoming phone number in our records and matchable to an account, thus, would we have extra permissions
    # is the incoming the owner - well, is it on the owners phone, highly unlikely, but possible
    # is the incoming a connection
    # strip down son
    if patient.account.mobile_phone
      if patient.account.mobile_phone.gsub(/\D/, '').last(10) != params['From'].gsub(/\D/, '').last(10)
        sound_the_alarm = true
      end
    else
      sound_the_alarm = true
    end

    # TODO: check if incoming is an emergency contact


    # handle errors, aka, normal people spamming this number with a helpful response
    # if necessary

    # return a basic level of info (public)
    # name, age
    # blood type
    # DNR, AD present
    # return some basic instructions (such as call 911 in an emergency)
    medical_details = ""

    # TODO: super dope extra credit, look up the local police for the origin

    # TODO: use our templating library to generate the body here with more richness
    message = "RECORD DETAILS\n"
    message << "Name: #{patient.first_name}\n"
    message << "Age: #{patient.age_str}\n"
    message << "Blood Type: #{Patient.blood_types[patient.blood_type].to_s}\n" if patient.blood_type.present?
    alerted_medications = patient.alerted_medications
    message << "\nMEDICATION ALERTS\n" unless alerted_medications.empty?
    alerted_medications.each do |medication|
      message << "#{medication.therapy}\n"
    end
    allergies = patient.allergies
    message << "\nALLERGIES\n" unless allergies.empty?
    allergies.each do |allergy|
      message << "#{allergy.allergen}\n"
    end
    contacts = patient.patient_contacts.select { |c| (c.privacy == privacy_level) && (c.home_phone.presence || c.mobile_phone.presence) }
    message << "\nEMERGENCY CONTACTS\n" unless contacts.empty?
    contacts.each do |contact|
      contact_number = contact.home_phone.presence || contact.mobile_phone.presence
      message << "#{contact.first_name}: #{contact_number}\n"
    end
    if sound_the_alarm
      message << "\nEmergency contacts have been notified and your request has been logged. If this is an emergency, please call 911."
    else
      message << "\nWe recognize this as your number so emergency contacts have not been notified!"
    end
    message << "\n\nScan with HealthNotifier App for full profile."

    twiml = Twilio::TwiML::Response.new do |r|
      r.Message message
    end

    # log it
    audit = Audit.new
    # audit.scanner_account_id = @account.account_id
    audit.scanner_phone_number = params['From']
    audit.lifesquare = ls.lifesquare_uid
    audit.is_provider = is_provider
    audit.is_owner = is_owner
    audit.privacy = privacy_level
    # audit.ip = request.remote_ip
    audit.platform = 'sms'
    audit.save

    # TODO: adventures of Zork, this is a second hit on this method, but with context
    # IS THIS AN EMERGENCY (Y or N)
    # send appropriate notification to emergency contacts (different template)
    # also send the follow SMS to the scanner with the patient photo
    # need to maintain a snappy response to twilio doh set(wait: 2.seconds).
    if sound_the_alarm
      PostsmsscanNotificationJob.perform_later(params['From'], patient.patient_id)
    end

    # send the response to twilio
    render :xml => twiml.text
  end

end
