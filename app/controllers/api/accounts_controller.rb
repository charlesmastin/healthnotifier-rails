require 'twilio-ruby'

module Api
  class AccountsController < Api::ApplicationController
    before_action :authenticate_account, only: [:get, :verify_credentials, :update, :delete, :update_password, :notifications, :update_location, :create_device, :update_device, :delete_device]

    def create
      # TODO: this isn't really auth, but oh well??
      # {
      #       "FirstName": "John",
      #       "LastName": "Donkey,
      #       "Email": "john@donkey.com",
      #       "MobilePhone": "4152796521"
      #       "Password": "asemicomplexpassword",
      #       "DOB": "08/02/2014",
      #       "ProfilePhoto": {
      #           "File": "base64ofyourfile",
      #           "Name": "legacyfilename.jpg",
      #           "Mimetype": "image/jpg"
      #       }
      #   }

      # TODO: put checking around dis here statement, son and catch, this doesn't work
      existing_account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", params[:Email].downcase).first
      if existing_account
        render json: {
          :success => false,
          :message => "An account with this email already exists!"
        }, status: 400
        return
      end

      account = Account.new(
        :email => params[:Email],
        :password => params[:Password],
        :password_confirmation => params[:Password]
      )

      if params[:MobilePhone]
        # we must validate against the service at this point, otherwise no, we shouldn't accept the request
        valid_phone = false
        number = PhoneValidator.call(params[:MobilePhone])
        if number != nil
          # look at the details, meh meh, probably should roll this bit into the service but whatevs
          if number.carrier['type'] == 'mobile'
            valid_phone = true
          end
        end
        if valid_phone
          # TODO: use the formatted number in E.164 format
          account.mobile_phone = number.phone_number #params[:MobilePhone] 
        else
          render json: {
            :success => false,
            :message => "Account requires a valid mobile phone, not a landline."
          }, status: 400 # hopefully the clients haven't overloaded things and will show this message
          return
        end
      end

      
      patient = Patient.create()
      
      if params[:DOB]
        patient.birthdate = DateTime.strptime(params[:DOB], "%m/%d/%Y")
      else
        # default at the beginning of time - this is bad news
        # from a UX perspective we meh want to require DOB on the up front web form
        # from a validation perspective we currently need it
        patient.birthdate = Date.new(1, 1, 1) # we'll have to mop this later
      end
      patient.first_name = params[:FirstName]
      patient.last_name = params[:LastName]

      # FML
      if account.save
        patient.create_user = account.account_id
        patient.update_user = account.account_id
        patient.account_id = account.account_id
      else
        # total bail zone
      end

      if account.save and patient.save
        # determine the platform used but default to web son
        # TODO: peep on dem headers but better yet, no, peep your self sillies
        # maybe we use User-Agent or maybe we actually submit the platform as an attribute, that's way simpler, lul
        account.signup_web! # but we can't seem to use this before saving the record # FAIL BRO

        
        if params[:MobilePhone]
          # this no longer needs to happen
          # patient_contact = patient.patient_contacts.create
          # patient_contact.create_user = account.account_id
          # patient_contact.update_user = account.account_id
          # patient_contact.contact_relationship = 'SELF'
          # patient_contact.first_name = patient.first_name
          # patient_contact.last_name = patient.last_name

          # patient_contact.home_phone = account.mobile_phone
          # patient_contact.mobile_phone = account.mobile_phone
          # patient_contact.email = account.email
          # patient_contact.record_order = 0
          # patient_contact.privacy = 'private'
        end

        if params[:ProfilePhoto]
          # attempt to persist to S3 and given our current lack of inbound CROP town, try to set some defaults
          if patient.add_profile_photo(params[:ProfilePhoto], true)
            patient.save
          else
            # we failed at persisting the image, but I dunno if we should bail on the whole deal
            # upload failed bomb out son
            #render json: {
            #  :success => false,
            #  :message => "Error saving to S3"
            #}, status: 500
            # return
          end
        end

        # TODO: only do this for web clients though, hmm
        sign_in(:account, account)
        # NOT VALID FOR mobile auth though

        render :json => {
          :success => true,
          :patient_id => patient.uuid,
          :account_id => account.uid
        }
        return
        

      else
        # roll back and delete that account son, and patient
        if account
          account.delete()
        end
        if patient
          patient.delete()
        end
      end

      # TODO: login and return token, for convenience? hmm, or just have client hit the login endpoint for consistency
      # well perhaps something else went wrong
      render json: {
        :success => false,
        :message => "Unexpected Error"
      }, status: 500
    end

    def create_basic
      # TODO: validation bro
      unless params[:email] && params[:password] && params[:phone]
        render json: {
          :success => false,
          :message => "Bad Request: Missing Required Attributes"
        }, status: 400
        return
      end
      # TODO: dry up, and resolve somehow as a mode of "create" where we simply skip the patient part
      # email
      # password
      # phone
      # that's it son
      existing_account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", params[:email].downcase).first
      if existing_account
        render json: {
          :success => false,
          :message => "An account with this email already exists!"
        }, status: 400
        return
      end

      account = Account.new(
        :email => params[:email],
        :password => params[:password],
        :password_confirmation => params[:password]
      )

      # this is duplicate
      if params[:phone]
        # we must validate against the service at this point, otherwise no, we shouldn't accept the request
        valid_phone = false
        number = PhoneValidator.call(params[:phone])
        if number != nil
          # look at the details, meh meh, probably should roll this bit into the service but whatevs
          if number.carrier['type'] == 'mobile'
            valid_phone = true
          end
        end
        if valid_phone
          # TODO: use the formatted number in E.164 format
          account.mobile_phone = number.phone_number #params[:MobilePhone] 
        else
          render json: {
            :success => false,
            :message => "Account requires a valid mobile phone, not a landline."
          }, status: 400 # hopefully the clients haven't overloaded things and will show this message
          return
        end
      end

      if account.save
        # TODO: look at platform headers bro bra
        # apparently they don't exist… meh
        account.signup_native_ios!
        account.save

        # token auth at this point, for convenience though bro
        # this is slightly ghetto though vs chaining the requests

        render :json => {
          :success => true,
          :account_id => account.uid
        }
        return
      end

      render json: {
        :success => false,
        :message => "Unexpected Error"
      }, status: 500
    end

    # self-onboarding business/enterprise accounts
    def create_enterprise
      # first_name
      # last_name
      # business_name
      # business_phone
      # email (copy over to org.email)
      # password
      # some other details???
      existing_account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", params[:email].downcase).first
      if existing_account
        render json: {
          :success => false,
          :message => "An account with this email already exists!"
        }, status: 400
        return
      end

      account = Account.new(
        :email => params[:email],
        :password => params[:password],
        :password_confirmation => params[:password]
      )

      # signup refer doh

      existing_org = Organization.where("lower(name) = ?", params[:business_name].downcase).first
      if existing_org
        render json: {
          :success => false,
          :message => "An organization with this name already exists!"
        }, status: 400
        return
      end


      # TODO: soft save the phone, no hard checking of types
      org = Organization.create()
      org.name = params[:business_name]
      org.contact_first_name = params[:first_name]
      org.contact_last_name = params[:last_name]
      org.contact_email = params[:email]
      org.contact_phone = params[:business_phone]

      # I am too lazy to RTFM, could we save the membership ahead of time, probably though
      if account.save and org.save

        membership = AccountOrganization.create(
          :role => "OWNER",
          :organization_id => org.organization_id,
          :account_id => account.account_id
        )

        if membership.save
          account.signup_web!
          sign_in(:account, account)
          # client is responsible for redirection, of course, dis an API
          render :json => {
            :success => true,
            :account_id => account.uid
          }
          return

        else
          # bombzone
        end

      else
        # ROLL IT BACK BRO
        if account
          account.delete()
        end
        if org
          org.delete()
        end
      end

      render json: {
        :success => false,
        :message => "Unexpected Error"
      }, status: 500
    end

    def get
      # additional scope
      # account = Account.where(:uid => params[:uid]).first
      # if account != @account
      #   render json: {
      #     :success => false,
      #     :message => "Permission Denied: Must Be Owner"
      #   }, status: 403
      #   return
      # end
      # ok, a compatibility shim to tide us over
      # establish an account, how? based only on creds doh son
      # where my exception handling at?
      json = @account.legacy_api_json()

      # merge in our device id if we has it though
      # merge in some push enabled business if this particular device endpoint is wired up though

      json[:PushEnabled] = false
      if params[:device_token] != nil
        account_device = AccountDevice.where(:device_token => params[:device_token]).where.not(:endpoint_arn => nil).first
        if account_device != nil
          json[:PushEnabled] = true
        end
      end

      render json: json, status: 200
    end

    def verify_credentials
      # basically check if username and password are correct for purposes of saving encrypted passwords on clients post authentication flow
      # yea son
      if @account.valid_password?(params[:password])
        # 200
        render json: {
          :success => true,
          :message => "Credentials Valid"
        }, status: 200
      else
        # 404, meh meh
        render json: {
          :success => true,
          :message => "Credentials Invalid"
        }, status: 400
      end
    end

    def update
      # how is the params sanitizer stepping in, it doesn't make sense though
      # {

      # "Email": "somesweet@domain.com",
      # "MobilePhone": "4152095050", (optional)
      # "CurrentPassword": "sweetSauceZone" (optional but required if NewPassword)
      # "NewPassword": "donkeytownUSA™" (optional)
      #}
      # for RESTfulness, have the id as the param
      account = Account.where(:uid => params[:uid]).first
      if account != @account
        render json: {
          :success => false,
          :message => "Permission Denied: Must Be Owner"
        }, status: 403
        return
      end

      # are we updating the email and mobile phones
      # careful these have Unique indexes

      account.email = params[:Email]
      # OMG son, remove it if it is nil, already, this shoudl require confirmation on the UI if clearing, but w/e
      if params[:MobilePhone] == nil
        account.mobile_phone = nil
      end
      if params[:MobilePhone] != nil
        # validate that it's legit my son
        # account.mobile_phone = params[:MobilePhone]
        if account.mobile_phone == params[:MobilePhone]
          # NON OP SON
        else
          valid_phone = false
          number = PhoneValidator.call(params[:MobilePhone])
          if number != nil
            # look at the details, meh meh, probably should roll this bit into the service but whatevs
            if number.carrier['type'] == 'mobile'
              valid_phone = true
            end
          end
          if valid_phone
            # TODO: use the formatted number in E.164 format
            account.mobile_phone = number.phone_number #params[:MobilePhone] 
          else
            render json: {
              :success => false,
              :message => "Account requires a valid mobile phone, not a landline."
            }, status: 400 # hopefully the clients haven't overloaded things and will show this message
            return
          end
        end

      end

      # are we attempting to reset the password
      # if so, ensure we're all set
      if params[:CurrentPassword] != nil and params[:NewPassword] != nil
        # validate the current password
        if account.valid_password?(params[:CurrentPassword])
          # one could hack around that by doing
          # TODO: check the devise API method for doing this, considering the hash and so on
          account.password = params[:NewPassword]
          account.password_confirmation = params[:NewPassword]

          # TODO: logout connected devices, cycle tokens, etc

        else
          render json: {
            :success => false,
            :message => "Invalid Password"
          }, status: 400
          return
        end
      end

      if account.save
        begin
          flash[:notice] = 'Account Update Success'
        rescue
          # ghetto town
        end
        render json: {
          :success => true,
          :message => "Account Updated"
        }, status: 200
      else
        render json: {
          :errors => account.errors,
          :success => false,
          :message => "Validation Errors"
        }, status: 400
      end
    end

    def delete
      ## Begin actual "deleting" here
      # because we may end up having additional things trigger on each individual patient, avoid re-triggering already deleted patients
      patients = Patient.where(:account_id => @account.account_id)
      cancelled_coverages = []
      patients.each do |patient|
        # bla bla bla, actually, we need to move the logic from the patient.delete api handler into the model, BLA BLA
        cancelled = patient.cancel_coverage
        if cancelled
          cancelled_coverages.push(patient)
        end

        patient.deleted!
        patient.save
      end

      # now delete the account
      @account.deleted!
      # wipe the mobile auth token - this should NOT BE JUST WILLY NILLY HERE
      @account.destroy_tokens
      @account.save

      # TODO: also, send an email to the owner (perhaps with recorvery info), and our support staff
      # probably already some devise default up in here, but I could never find the controller route anyhow, lolzors
      # TODO: log in analytics


      # TODO: log out user for good measure on server too
      sign_out @account
      # lazily attempt to save dat feedback
      if params[:ExitSurvey] != nil
        process_exit_survey params[:ExitSurvey]
      end

      # send the email son
      email = @account.email
      if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
        subject = "Lifesquare Account Closed"
        begin
          AccountMailer.send_email(email, subject, 'accounts/mailer/delete', {
            :account => @account,
            :patients => patients,
            :cancelled_coverages => cancelled_coverages
            }).deliver_later
        rescue
          # woot not much to see
        end
      end

      # TODO: disable all ARN endpoints
      # so we stop getting dat push

      # return appropriate status for extra credit      
      render json: {
        :success => true,
        :message => "Account Deleted"
      }, status: 200

      # presumably all clients will handle the termination here
    end

    def begin_recovery
      # this is basically that other form son
      # we could use this to actually undelete an account as well, aka full recovery
      # # #
      if params[:MobilePhone].present? and params[:Email].present?
        account = Account.where("lower(email) = ?", params[:Email].downcase).first
        if account
          # now strip all the characters and match the strings
          # if we can't find the phone, send the email anyhow
          # let's do something crazy for the moment, and just match the last 10, so we can not care about (1) being input into the DB
          
          if account.mobile_phone.present? and account.mobile_phone.gsub(/\D/, '').last(10) == params[:MobilePhone].gsub(/\D/, '').last(10)
            phonenum = account.mobile_phone.gsub(/\D/, '')

            recovery_code = 6.times.map { (0..9).to_a.sample }.join
            account.unlock_token = recovery_code
            account.save

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
                @client = Twilio::REST::Client.new(
                  Rails.configuration.twilio[:account_sid],
                  Rails.configuration.twilio[:auth_token]
                )
                message = @client.account.messages.create(:body => "Lifesquare Recovery Code is #{recovery_code}",
                    :to => scrubbed_number,
                    :from => Rails.configuration.twilio[:phone_number])
            rescue Twilio::REST::RequestError => e
                render json: {
                  :errors => e.message,
                  :success => false,
                  :message => "SMS Failure"
                }, status: 500
            end
            render json: {
              :success => true,
              :channel => 'sms'
            }
            return
          else
            # DRY IT UP SON BUNS HONS
            token = account.send_reset_password_instructions
            if token
              render json: {
                :success => true,
                :channel => 'email'
              }
              return
            else
              render json: {
                :success => false,
                :message => "Unexpected Error"
              }, status: 500
              return
            end
          end

          

        else
          render json: {
            :success => false,
            :message => "No Account Found"
          }, status: 404
          # allow it to pass, in case we just have a matching email
        end
      elsif params[:Email].present?
        account = Account.where("lower(email) = ?", params[:Email].downcase).first
        if account.nil?
          render json: {
            :success => false,
            :message => "No Account Found"
          }, status: 404
          return
        end

        token = account.send_reset_password_instructions
        if token
          render json: {
            :success => true,
            :channel => 'email'
          }
          return
        else
          render json: {
            :success => false,
            :message => "Unexpected Error"
          }, status: 500
          return
        end
      end
    end

    def recover
      # do the recovering, email is going to map directly into a standard devise helper
      # this is mobile phone only short code matching
      account = Account.where(:unlock_token => params[:UnlockCode]).first
      if account.nil? || account.mobile_phone.presence.nil? || params[:MobilePhone].presence.nil? ||
        (account.mobile_phone.gsub(/\D/, '').last(10) != params[:MobilePhone].gsub(/\D/, '').last(10))
        render json: {
          :success => false,
          :message => "Invalid Unlock"
        }, status: 404
        return
      end

      account.unlock_token = nil
      account.reset_password_token = nil
      account.confirmed_at = DateTime.now
      account.save
      # this is a confirmation too
      # at least we know we can be reached via SMS, so just go ahead and confirm the account
      # sign_in(:account, account)
      token, enc = Devise.token_generator.generate(account.class, :reset_password_token)
      account.reset_password_token = enc
      account.reset_password_sent_at = Time.now.utc
      account.save(validate: false)
      
      # token = account.set_reset_password_token
      render json: {
        :token => token,
        :redirect => edit_password_url(account, reset_password_token: token),
        :success => true
      }

      # zero out the things
      # also, get the end-user whisked along to the new password flow yea yea yea son
    end

    # AKA save up dat new password, with our token doh
    def complete_recovery
      # TODO: hook devise time duration for validity HERE at some point
      token = Devise.token_generator.digest(Account, :reset_password_token, params[:Token])
      account = Account.where(:reset_password_token => token).first
      if account == nil# || account.reset_password_sent_at + Now + (date interval)
        render json: {
          :success => false,
          :message => "Invalid Token"
        }, status: 404
        return
      end

      # TODO valid password check again? or maybe the model just does it, w/e
      account.password = params[:Password]
      account.password_confirmation = params[:Password]
      account.reset_password_token = nil
      account.reset_password_sent_at = nil
      # wipes all tokens not associated to a device
      # TODO: should this in fact wipe all tokens?
      account.destroy_tokens # .destroy_all_tokens

      if account.save
        render json: {
          #:account_uuid => account.uid,
          :email => account.email,
          :success => true,
          :message => "Account Updated"
        }, status: 200
      else
        render json: {
          :errors => account.errors,
          :success => false,
          :message => "Validation Errors"
        }, status: 400
      end
    end

    # DEPRECATED BUT in production mobile apps < 1.4.0
    def password_reminder
      account = Account.where("lower(email) = ?", params[:Email].downcase).first
      if account == nil
        render json: {
          :success => false,
          :message => "Invalid email"
        }, status: 404
        return
      else
        token = account.send_reset_password_instructions
        if token
          render json: {
            :success => true
          }
          return
        else
          render json: {
            :success => false,
            :message => "Unexpected Error"
          }, status: 500
          return
        end
      end
    end

    def notifications
      # if request.headers["Lifesquare-Client-Version"] == nil
      render json: {
        :success => true,
        :invites => @account.pending_invites
      }, status: 200
    end

    def update_location
      # null true on location columns kinda makes it hard to do all the fancy stuffs, IMO
      begin
        location = AccountLocation.where(:account_id => @account.account_id).first
        if location == nil
          AccountLocation.create(
            :account_id => @account.account_id,
            :latitude => params[:latitude],
            :longitude => params[:longitude]
          )
        else
          # avoid whitelisting params by doing this
          location.latitude = params[:latitude]
          location.longitude = params[:longitude]
          location.save
        end
        render json: {
          :success => true,
        }, status: 200
      rescue
        render json: {
        }, status: 500
      end
    end

    def exit_survey
      # basically only permit the desired keys, too bad I don't know how to do this in ruby
      process_exit_survey({
        :AccountId => params[:AccountId],
        :Reasons => params[:Reasons],
        :Other => params[:Other]
      })
      render json: {
        :success => true
      }, status: 200
    end

    # devices - not enough for their own controller at this point though
    def create_device
      # THIS IS REALLY JUST store token for device, where we create a device if necessary
      # This API is called every login/authenticated startup on iOS
      # Also called periodically on Android, but primarily upon first launch

      # TODO: add push_enabled bool because we can track this client side so we avoid hitting this for messages (aka counting on this channel)
      # however, we are still able to send silent pushes

      # http://stackoverflow.com/questions/22501373/amazon-sns-how-to-get-endpointarn-by-tokenregistrationid-using-amazon-net-sd
      # http://docs.aws.amazon.com/sdkforruby/api/Aws/SNS/Client.html
      # as noted in the locations, we need to do a little extra work on our end if we're going to pass the user data
      # basically we need to be mostly certain there isn't an existing endpoint with this token
      # and if we mess up, we should (LOL) try to parse the error message for the existing arn and re-map things
      # nicely done amazon

      # existing token in our db
      device = AccountDevice.where(:device_token => params[:device_token]).first
      if device != nil
        if device.account_id != @account.account_id
          # another account was using this device, let's take over ownership
          device.account_id = @account.account_id
          # TODO: update the user_data on the SNS side, just for record keeping though
        else
          # nothing at the moment, since we're just passing through
        end
      else
        device = AccountDevice.new
        device.account_id = @account.account_id
        device.device_token = params[:device_token]
      end

      # TODO: refactor all the things so we also track devices regardless of push permissions 
      # headers supply the account that is authorized, so that's enough for now
      # {
      #   "device_token": "blbalbaalb",
      #   "client_version": "1.4.5", # blbalbalbablablalba
      #   "platform": "ios" # "android" "web", need minor support when we add desktop push bra
      # }

      # ok, depdending on device_token generation, it's possible we could collide
      # TODO: check for existing with same account_id
      # TODO: more accurate http responses

      # TODO: this table is basically only added for mobile clients with opt-in, it's not a raw tracking table
      if request.headers["Lifesquare-Client-Version-Name"].present?
        device.client_version = request.headers["Lifesquare-Client-Version-Name"]
      end
      if request.headers["Lifesquare-Client-Version"].present?
        device.client_build = request.headers["Lifesquare-Client-Version"].to_s # meh meh meh
      end
      device.platform = params[:platform]
      
      if device.new_record? || !device.endpoint_arn.present?
        # meh meh meh
        # all da way do da SNS brizzle
        # at the moment, everything becomes an endpoint
        sns = SNSNotification.get_client
        arn = nil
        if device.platform == "ios"
          # production mode here
          arn = "arn:aws:sns:us-west-2:631082279464:app/APNS/lifesquare-ios"
          # dev mode only here - because in local Xcode builds, tokens are only for the sandbox
          # http://stackoverflow.com/questions/39625258/xcode-8-aps-environment-entitlement-wont-set-to-production
          # TODO: or we're on beta / staging servers, thus allowing us to connect
          # TODO: or the incoming request has some signature of a non release xcode build
          if Rails.env == 'development'
            arn = "arn:aws:sns:us-west-2:631082279464:app/APNS_SANDBOX/lifesquare-ios-dev"
          end

        end
        if device.platform == "android"
          # TODO: put in configuration bro
          arn = "arn:aws:sns:us-west-2:631082279464:app/GCM/lifesquare-fcm"
        end
        if arn != nil
          # who cares about any existing endpoints, they will eventually be mopped up
          # TODO: apparently we do care about existing endpoints
          # Aws::SNS::Errors::InvalidParameter (Invalid parameter: Token Reason: Endpoint "xxxxx" already exists with the same Token, but different attributes.):
          if device.new_record?
            device.save
            # currently struggling with our uuid before_create meta stuffs in the model
          end
          begin
            endpoint = sns.create_platform_endpoint({
              platform_application_arn: arn,
              token: device.device_token,
              custom_user_data: { account_uuid: @account.uid, device_uuid: device.uuid }.to_json
            })
          rescue Aws::SNS::Errors::InvalidParameter => e
            # TODO: parse the stuffs though
            # Endpoint arn:aws:sns:us-west-2:631082279464:endpoint/APNS_SANDBOX/lifesquare-ios-dev/2735bb29-2e9e-3b60-a56a-a83ea73f8597
          end

          # TODO: manage subscriptions to topics
          # subscribe to the platform-notifications topic
          # arn:aws:sns:us-west-2:631082279464:platform-notification

          # subscribe to the platform-ios or platform-android
          # we don't know the organization yet
          # we don't know the provider status yet

          begin
            # learn how to handle for real doe
            if endpoint.endpoint_arn.present?
              device.endpoint_arn = endpoint.endpoint_arn
            end
          rescue
            # meh it didn't work, no push push for you
          end
        end
        # not necessary… at all
        # SNSNotification.notify_device(device, "Welcome to Lifesquare")
      end

      if device.save
        # checks for tokens and all dat silly zone

        # map the device.device_id onto the token, because why not pollute all the things
        # thus now the 3rd and final time we're looking up da token…
        if request.headers['Authorization'] && request.headers['Authorization'].include?("Bearer")
          token = request.headers['Authorization'].split(" ")[1]
          # this is so verbose
          account_token = AccountToken.where(:token => token).first
          if account_token != nil
            account_token.account_device_id = device.account_device_id
            account_token.save
          end
        end

        render json: {
          :uuid => device.uuid,
          :success => true,
        }, status: 200
      else
        render json: {
        }, status: 500
      end
    end

    def update_device
      # API NOT IN USE
      # primary goal here, is updating client version and so on, presumably this will be frequently called
      # in the future, as the table is broader in scope, we would update additional params, and query by uuid
      # perhaps that's a different endpoint though
      device = AccountDevice.where(:account_id => @account.account_id, :device_token => params[:device_token]).first
      if device != nil
        # at the moment, who cares about ownership
        # avoid mass assignment for now
        # unsure if we're going to be feeding in the device_token, of course we are
        # this design requires the burden on the client to sift through records and update, no bueno
        if request.headers["Lifesquare-Client-Version-Name"].present?
          device.client_version = request.headers["Lifesquare-Client-Version-Name"]
        end
        if request.headers["Lifesquare-Client-Version"].present?
          device.client_build = request.headers["Lifesquare-Client-Version"].to_s # meh meh meh
        end
        if device.save
          render json: {
            :uuid => device.uuid,
            :success => true,
          }, status: 200
        else
          render json: {
          }, status: 500
        end
      else
        render json: {
        }, status: 404
      end

    end

    def delete_device
      # this is probably almost never ever used directly
      # if there is some magical way to call stuff at uninstall time, perhaps
      # naturally for now, this could be seen as a 1-1 with desired delivery endpoints
      # but it's not
      # user opt-out of push notifications
      # hmmm but is this really what we want to do though, do we-respect that, or do we just stop sending non data pushes (I think that one)

    end

  private

    def process_exit_survey(params)
      # just email charles for now, persist or something fun later
      begin
        account = Account.where(:uid => params[:AccountId]).first
        account.exit_survey = params
        account.save
      rescue
        # log it somewhere ???
      end
    end

  end
end
