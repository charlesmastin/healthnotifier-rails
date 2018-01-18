module Api
  class ProvidersController < Api::ApplicationController
    before_action :authenticate_account
    before_action :require_lifesquare_employee, only:[:approve_request, :deny_request]

    def register
      # {
      #       "PatientId": "LOLOBROLO",
      #       "LicenseNumber": "123abcfunkytown",
      #       "LicenseBoard": "DIY Physicians United",
      #       "State": "CA",
      #       "Expiration": "01/01/2020",
      #       "SupervisorName": "J Smith Overseer",
      #       "SupervisorEmail": "jsmithers@hospital.edu",
      #       "SupervisorPhone": "4152138890",
      #       "SupervisorExt": "20",
      #       "CredentialFiles": [
      #           {
      #               "File": "base64ofyourfile",
      #               "Name": "legacyfilename.jpg",
      #               "Mimetype": "image/jpg"
      #           }
      #       ]
      #   }

      
      # TODO: this is the end of the extractable auth code

      # swoop in and check for those existing creds son
      # TODO: block subsequent requests on in-progress or approved credentials, lul because it somehow sets the account back to PATIENT, LUL
      # There is currently 0 mobile product use case for subsequent submission (eg for follow up with license)
      # That said, the portal is a giant CLUSTER F with the form just taking up all the space. Time to move that shee to the accounts or it's own modal, OMG DIAF

      # do we have approved stuff, aka are we a provider already
      # put our faith in the cron job to deauth expired peoples
      # TODO: revisit our faith assessment of the cron (Ram / Chris Code ???)

      # well let's see I didn't handle the actual response codes in the mobile clients because I skipped this use case…
      # by preventing submission, so we can't just go willy nilly until I check that source code
      if @account.provider?
        render json: {
          :success => false,
          :message => "Account is already an approved provider!"
        }, status: 500
        return
      end

      # newly introduced, optional here
      if params[:PatientId] == nil
        patient = Patient.where(:account_id => @account.account_id).order('create_date').first
      else
        patient = Patient.where(:account_id => @account.account_id, :uuid => params[:PatientId]).first
        if patient == nil
          render json: {
            :success => false,
            :message => "Patient not found!"
          }, status: 404
          return
        end

      end

      # TODO: do we have in-progress stuff, actually use the damn enums from the class already, already
      creds = ProviderCredential.where(:status => 'PENDING', :patient_id => patient.patient_id)
      if creds.length > 0
        render json: {
          :success => false,
          :message => "Credentialing already in-progress"
        }, status: 500
        return
      end

      if params[:SupervisorEmail].downcase == @account.email.downcase
        render json: {
          :success => false,
          :message => "Bad request: Supervisor email can't be same as account email"
        }, status: 400
        return
      end

      # TODO: in a perfect world, share the logic
      # in the ghetto hacked collection controller for this
      # OMG good times, old times
      # don't even know what the collection looks like because of the epic sweet controller

      # TODO: support lookup first
      # if params[:id]
      cred = ProviderCredential.new
      # get the "first lol lol lol lol lol shoot shoot" patient of the account
      # lots of overhead, instead expect the client to send on the patient_id, oh well, one can hope
      # we don't need to be confirmed on email to signup to be a provider, lol UX fail
      

      cred.patient_id = patient.patient_id

      # cherry pick dat tasty string formatter from the other branch
      tA = params[:Expiration].split('/')
      cred.expiration = DateTime.new(tA[2].to_i, tA[0].to_i, tA[1].to_i)
      # oh boy

      cred.license_number = params[:LicenseNumber]
      # need to validate to 2 characters in all clients
      # use a pick list SON
      cred.licensing_state_province = params[:State]
      cred.licensing_country = "US"
      cred.licensing_board = params[:LicenseBoard]
      cred.supervisor_name = params[:SupervisorName]
      cred.supervisor_contact_email = params[:SupervisorEmail]
      cred.supervisor_contact_phone = params[:SupervisorPhone]
      cred.supervisor_contact_phone_ext = params[:SupervisorExt]

      # File(s)
      if params[:CredentialFiles] and params[:CredentialFiles].length > 0
        # TODO: convert the stupid case sensitiviy, gotta love dat ruby json parsing bs

        document_info = {}
        document_info['category'] = 'PROVIDER_CREDENTIALS'
        document_info['files'] = []

        params[:CredentialFiles].each do |file|
          document_info['files'].push({
            'file' => file['File'],
            'name' => file['Name'],
            'mimetype' => file['Mimetype']
          })
        end

        # TODO: deal with file replacement, removal???

        document_digitized = UploadDocumentDigitized.call(document_info)
        converted_document_digitized = ConvertDocumentDigitized.call(document_digitized)
        cred.document_digitized = converted_document_digitized
      end

      if cred.save
        # TODO: env settings for sending notifications or not, as to not spam the crap out of staff

        # staff
        # TODO: the appropriate Staff email for this kinda thingy
        subject = "Provider Credentials Request for #{patient.fullname}"
        recipient = Rails.application.config.default_admin_email
        AccountMailer.send_email(recipient, subject, 'provider/mailer/support_notification_submission', {:provider_credential => cred }).deliver_later
        
        # account - why the hell are we still validating/verifying an email here
        email = @account.email
        subject = "Provider Credentials Received"
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          AccountMailer.send_email(email, subject, 'provider/mailer/account_notification_submission', {:provider_credential => cred }).deliver_later
        end

        # supervisor
        email = cred.supervisor_contact_email
        subject = "Lifesquare Credentials Request for #{patient.name_extended}"
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          AccountMailer.send_email(email, subject, 'provider/mailer/supervisor_notification_submission', {:provider_credential => cred }).deliver_later
        end

        render :json => { :success=>true }
      else
        render json: {
          :success => false,
          :message => "Snap, something went wrong"
        }, status: 500
        return
      end
    end

    def approve_request
      # byebug
      creds = ProviderCredential.where(:provider_credential_id => params[:id].to_i).first
      # DO NOT TRUST THE MODEL LOGIC AT THIS POINT IN TIME
      # TRUST NO ONE
      # this also will need to trigger pubsub / but that is on the model save

      # NOTIFICATIONS SON
      # F your encapsulation principals, this is where this happens
      # account - why the hell are we still validating/verifying an email here
      email = creds.patient.account.email
      subject = "Provider Access Approved"
      if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
        AccountMailer.send_email(email, subject, 'provider/mailer/account_notification_approved', {:provider_credential => creds }).deliver_later
      end

      creds.accepted!
      creds.credentialed = true
      creds.patient.account.provider!
      creds.save
      creds.patient.account.save

      SNSNotification.provider_status_change(creds)
      # TODO: follow with specific silent push

      # meh
      render :json => { :success=>true }
    end

    def deny_request
      creds = ProviderCredential.where(:provider_credential_id => params[:id].to_i).first
      # DO NOT TRUST THE MODEL LOGIC AT THIS POINT IN TIME
      # TRUST NO ONE
      # this also will need to trigger pubsub / but that is on the model save

      # NOTIFICATIONS SON
      # F your encapsulation principals, this is where this happens
      email = creds.patient.account.email
      subject = "Provider Access Denied"
      if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
        AccountMailer.send_email(email, subject, 'provider/mailer/account_notification_declined', {:provider_credential => creds }).deliver_later
      end

      creds.rejected!
      creds.credentialed = false
      creds.patient.account.patient!
      creds.save
      creds.patient.account.save

      SNSNotification.provider_status_change(creds)
      # TODO: follow with specific silent push

      # meh
      render :json => { :success=>true }
    end

  end
end
