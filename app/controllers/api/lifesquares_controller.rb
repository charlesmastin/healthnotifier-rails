module Api
  class LifesquaresController < Api::ApplicationController
    before_action :authenticate_account, except: [:image]
    before_action :require_provider, only: [:nearby, :search]
    before_action :require_lifesquare_employee, only: [:create_batch]

    def scan
      if params[:id]

        # TODO: consider the social network, consider patient scans own lifesquare, bla
        # TODO: be sure the account we're looking up has been paid for
        ls = Lifesquare.where( :lifesquare_uid => params[:id].upcase).first

        # this is debateable, but assume we have to be logged in and we're logging requests
        if ls == nil
          render json: {
            :success => false,
            :message => "No lifesquare found"
          }, status: 404
          return
        end

        # if not verified, verify
        if ls.valid_state == 0
          ls.valid_state = 1
          ls.save
          render json: {
            :success => false,
            :message => "Activated Lifesquare"
          }, status: 404
          return
        end

        patient = Patient.where(:patient_id => ls.patient_id, :confirmed => true, :status => 'ACTIVE').first
        if patient == nil
          render json: {
            :success => false,
            :message => "No patients for lifesquare"
          }, status: 404
          return
        end

      elsif params[:mine]
        # THIS SHOULD BE DROPPED IN A FEW MONTHS - IT IS NO LONGER IN USE, EXCEPT LEGACY CLIENTS
        # TEST FOR CONSISTENCY
        begin
          patient = Patient.where(:account_id => @account.account_id, :confirmed => true, :status => 'ACTIVE').order('create_date').first
          ls = Lifesquare.where(:patient_id => patient.patient_id, :valid_state => 1).first
        rescue
          render json: {
            :success => false,
            :message => "You don't have a lifesquare"
          }, status: 404
          return
        end
      end

      view_permission = patient.view_permission_for_account(@account)
      residence = nil
      residences = PatientResidence.where(:patient_id => patient.patient_id).order('record_order')
      # iterate and attempt to find a suitable privacy mapping
      residences.each do |r|
        # jerry hates me
        if Patient::obj_has_view_permission(r, view_permission)
          residence = r
          break
        end
      end
      # this contrasts our permissions concept that we could in effect hide an address entirely
      residence_json = nil
      if residence != nil
        residence_json = format_residence_json(residence)
      else
        # TOP FIX OF THE CENTURY
        residence_json = {
          :Address1 => '',
          :Address2 => '',
          :City => '',
          :State => '',
          :Postal => 0, # this is a tremendous and temparay hack for Android because the data was modelled as an integer
          :Latitude => '',
          :Longitude => '',
          :LifesquareLocation => ''
        }
      end

      expires = 1.hour.from_now
      if @account.provider?
        expires = 6.hour.from_now
      end

      return_json = {
        :Expires => expires,
        :PatientId => patient.uuid,
        :LifesquareId => ls.lifesquare_uid,
        :FirstName => patient.first_name,
        :LastName => patient.last_name,
        :Photo => patient_photo(patient, request), # old attribute, removing after next 2 released, 
          # it would be dope to have a framework for decorating deprecated things
        :ProfilePhoto => patient_photo(patient, request),
        :WebviewUrl => "%s%s%s" % [request.protocol, request.host_with_port, api_lifesquare_webview_path(ls.lifesquare_uid)],
        :WebviewTabs => [{:name => "Personal", :id => "personal"}, {:name => "Medical", :id => "medical"}, {:name => "Contacts", :id => "contacts"}]
      }

      if @account.account_id != patient.account_id
        # TODO: update to a keyword based signature, vs positional arguments
        PostscanNotificationJob.perform_later(@account.account_id, patient.patient_id, params[:latitude], params[:longitude])
        if @account.provider?
          #TODO: this survey needs to be ratelimited and updated, etc, also it needs to 
          #be delayed as in deliver in 10 min (otherwise it's gonna bombard the scanner app with notifications)
          
          begin
            subject = "Lifesquare Post Scan Survey"
            AccountMailer.send_email(@account.email, subject, 'accounts/mailer/post_scan_survey', {}).deliver_later(wait: 10.minutes)
          rescue
            # pass
          end
        end

        # LOG IF we're modern iOS, aka have a Lifesquare-Client-Version / etc
        # doh, iOS only as Android uses the webview
        # let's get real with our umm headers, as we MAY have to provisionally check platform
        # F it, android can double log / not log in the webview / w/e
        audit = Audit.new
        audit.scanner_account_id = @account.account_id
        audit.lifesquare = ls.lifesquare_uid
        audit.is_provider = @account.provider?
        audit.is_owner = false
        audit.privacy = @view_permission
        if params[:latitude] && params[:longitude]
          audit.latitude = params[:latitude]
          audit.longitude = params[:longitude]
        end
        audit.ip = request.remote_ip
        audit.save

      end

      if residence_json
        return_json[:Residence] = residence_json
      end
      render json: return_json
    end

    def nearby
      patients_to_serialize = []

      unless params[:latitude] && params[:longitude]
        render json: {
          :success => false,
          :message => "Bad Request: Missing latitutde or longitude paramaters"
        }, status: 400
        return
      end

      # 1609 meters in mile, so 1000m =
      # 1000m radius
      # raius in m, max radius 1000

      # TODO: have query constraint... chainable like Django???????
      addresses = PatientResidence.near("%s, %s" % [params[:latitude], params[:longitude]], 0.62)

      for address in addresses
        patient = Patient.where(:patient_id => address.patient_id, :confirmed => true, :status => 'ACTIVE').first
        if patient != nil
          patients_to_serialize.push([patient, address])
        end
      end
      # geocoder, near

      # limit radius

      # limit results?

      lifesquares = []
      patients_to_serialize.each do |item|
        lifesquares.push(format_provider_lifesquare_json(item[0], item[1], params[:latitude], params[:longitude]))
      end

      render json: {
        :Lifesquares => lifesquares
      }
    end

    def search
      # Currently this is only for providers, in the future, we could have different capabilites for general member (patient) search, as well as provider
      unless params[:keywords]
        render json: {
          :success => false,
          :message => "Bad Request: Missing or empty keywords paramaters"
        }, status: 400
        return
      end

      # utlize renderer, mixin, TODO: pagination, consider a limit for now as a quick fix
      # and I clearly cant program ruby
      # this is quite possibly the worst json serialization code, but it works
      lifesquares = []
      search_for_patients(params[:keywords]).each do |item|
        lifesquares.push(format_provider_lifesquare_json(item[0], item[1], params[:latitude], params[:longitude]))
      end

      render json: {
        :Lifesquares => lifesquares
      }
    end

    def webview
      # lowest permissions, in case something doesn't line up, and just for defaulting variables
      @owner = false

      ls = Lifesquare.where( :lifesquare_uid => params[:id].upcase, :valid_state => 1).first
      if ls == nil
        render json: {
          :success => false,
          :message => "No lifesquare found"
        }, status: 404
        return
      end
      @patient = Patient.where(:patient_id => ls.patient_id, :confirmed => true, :status => 'ACTIVE').first
      if @patient == nil
        render json: {
          :success => false,
          :message => "No patients for lifesquare"
        }, status: 500
        return
      end

      # are we the owner, regardless of being a provider - hard to say if we only look at patient_create_user or AP
      if @patient.account_id == @account.account_id
        @owner = true
      end

      @view_permission = @patient.view_permission_for_account(@account)

      @default_privacy_message = Rails.configuration.privacy_permission_denied_message

      @patient_details = @patient.get_details('*')

      # TODO: put in a view helper or something
      @privacy_options = Values.call('privacy')

      # TODO: this is wrong, but hey, it works
      @static_url = '%s%s/' % [request.protocol, request.host_with_port]

      response.headers["Expires"] = 1.hour.from_now.httpdate
      if @account.provider?
        response.headers["Expires"] = 6.hour.from_now.httpdate
      end

      rendered = render(:layout => false)
      return rendered
    end

    def image
      # does not care abour params for size, resolution, etc
      # does not validate active lifesquare, etc
      begin
        code = ActionController::Base.helpers.sanitize(params[:id])
        image_file = Dir.mktmpdir + "/" + "temp.png"
        # 
        content = "https://lsqr.net/#{code}"
        # content = "http://10.0.1.12:3000/lsqr/#{code}"
        system("qrencode -v2 -lQ -m0 -s8 -i -o #{image_file} #{content}")

        file = File.open(image_file, 'rb')
        data = file.read
        file.close
        File.delete(image_file) if File.exist?(image_file)
        
        send_data data, :type=> "image/png", :filename => "lifesquare-#{code}.png", :disposition => :inline
      rescue
        render text: "FAIL"
      end
    end

    def assign
      # TODO: reject on duplicates

      # TODO: determine what the heck campaign as it pertains to existing on a lifesquare
      # vs promo code assigning a capmaign attribution style keep this code flexible

      # TODO: reflow the steps again so we don't go bonkers 111/junkers 111 on this place
      # UX wise pre-validation has already occurred specifically, promo matching and price change, claiming lsq availability
      # consider discreet endpoints for thos

      # what is reasonable certainty that the transaction will work, we're probably making life hard on ourselves
      # we could also do transactions with Stripe via authorize + charge, etc, but that's more complicated
      # this is in-general, an exercise in design

      # step1: transactionally process on our side: so we can rollback if the payment fails, this is active verification
      # step2: process payment only if it works on our side
      # step3: commit /rollback transaction - aka send notifications
      # step4: return to client

      # risk is bombing mid-transaction and having a dirty state ugggg, a risk I am willing to take
      # it's unacceptable to charge and chargeback a customers credit card because of our potential problems

      # incoming request body
      # {
      #   Patients: [
      #     { 
      #       PatientId: "1239018231908210381309183",
      #       LifesquareId: null, LifesquareId: "", or missing LifesquareId… oh yea son
      #     },
      #     { 
      #       PatientId: "1239018231908210381309185",
      #       LifesquareId: "ABC123ABC"
      #     }
      #   ],
      #   Shipping: {
      #      ResidenceId: 102920,
      #   },
      #   PromoCode: "cheaptimes",
      #   Subscription: true,
      #   Payment: {
      #     ///// either one of these, but not both, in which case, use the token
      #     CardId: "12311231131",
      #     Token: "aadwaukdakuywad3aukhawkdha"
      #     AuthorizedTotal: 1100 // what the client expects to be charging, aka has seen as a total and "approved"
      #   }
      # }

      # Step 1: Transactional Processing - inline-validate and total fees
      errors = []

      requires_shipping = true
      shipping_address = nil
      
      transaction = {
        :success => false,
        # these are references to objects so we can roll them back if needed
        # double check which of these objects sets attributes on their 1:1 patient, if any
        :lifesquares_claimed => [],
        :lifesquares_generated => [],
        :charge => nil, # one time fee, costco bulk times, there can only ever be one? I think
        :subscriptions => [], # we have to spin up 1 per patient, lulz
        :payments => [], # our record of the one time fee, hmm, we will need one for each subscription though
        :coverages => [],
        :codesheetprintrequest => nil
        # it doesn't seem like we can actually pause the delivery of the notification objects, uggg, lol, look into that
        # however, we have a high degree of success with pre-validation, and using existing stripe info or a valid pre-tokenized card
      }
      credit_used = false
      credits_used = 0
      total_due = 0
      recurring = false # not part of the transaction, part of state
      cost_per_lifesquare = Rails.configuration.default_coverage_cost
      campaign = find_campaign_with_promo(params[:PromoCode])
      if campaign != nil
        cost_per_lifesquare = campaign.promo_price
        requires_shipping = campaign.requires_shipping
        if cost_per_lifesquare == 0
          credit_used = true
          # TODO: blocking on invalid credits
        end
      end

      

      # json validation ??? handle the crazy case, although not critical at all, production will just throw a 500 so no worries

      # TODO: cache the output operations of this validation, otherwise, we're duplicating logic, to some degree, w/e
      validated_codes = []
      params[:Patients].each do |p|
        # we're pretty darn sure it's a valid patient, but just in case
        # for now require owner
        # bombs if not owner, but that should never happen and will catch a 500
        # TODO: revist the need to have active patient here…
        patient = Patient.where(:account_id => @account.account_id, :uuid => p[:PatientId]).first
        if p[:LifesquareId] == nil || p[:LifesquareId] == ""
          # we need assignment, so do it now ok, so there is 0.0001% chance of collision within creating a new id
          total_due += cost_per_lifesquare
        else
          # we want to claim it, validate qualified lsq, this could easily return false
          lifesquare = Lifesquare.where(:lifesquare_uid => p[:LifesquareId]).first
          if lifesquare != nil and lifesquare.claimable?

            if validated_codes.include? lifesquare.lifesquare_uid
              errors.push({
                error: 'duplicate_lifesquares',
                patient_id: patient.uuid,
                message: "Lifesquare #{p[:LifesquareId]} has been requested multiple times"
              })
            else
              validated_codes.append(lifesquare.lifesquare_uid)

              # this was a
              unit_cost = cost_per_lifesquare

              if lifesquare.campaign != nil
                requires_shipping = lifesquare.campaign.requires_shipping
                if cost_per_lifesquare > lifesquare.campaign.user_shared_cost_for_campaign
                  unit_cost = lifesquare.campaign.user_shared_cost_for_campaign
                end
              end

              total_due += unit_cost
            end
          else
            errors.push({
              error: 'invalid_lifesquare',
              patient_id: patient.uuid,
              message: "Lifesquare #{p[:LifesquareId]} not available"
            })
          end
        end
      end

      if requires_shipping || params[:Shipping] != nil
        residence = PatientResidence.where(:patient_residence_id => params[:Shipping][:ResidenceId]).first
        if residence == nil
          errors.push({
            error: 'invalid_address',
            message: "Invalid Shipping Address"
          })
          render json: {
            :errors => errors,
            :success => false,
            :message => "Bad Request: Invalid Address"
          }, status: 400
          return
        else
          # you may ask we we both, vs passing a residence instance, beats me,
          # maybe we can optimize this later
          shipping_address = {
            :address_line1 => residence.address_line1,
            :address_line2 => residence.address_line2,
            :address_line3 => residence.address_line3,
            :city => residence.city,
            :state_province => residence.state_province,
            :postal_code => residence.postal_code,
            :country => residence.country
          }
        end
      end
      
      if errors.size > 0
        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Invalid Lifesquare(s)"
        }, status: 400
        return
      else
        # at this point we're optimistically certain everything will work
        # because we got through the list of any user claimed squares
        # those are our high-failure-risk guys
        # let's go ahead and spin up the squares, and coverages to ensure that portion works
        
        # establish our address from the Shipping . ResidenceId

        # THIS IS THE OPTIMISTIC PRE-COMMIT
        params[:Patients].each do |p|
          # TODO: REvisit the need for active patient here! Probably ok though
          patient = Patient.where(:account_id => @account.account_id, :uuid => p[:PatientId]).first
          if p[:LifesquareId] == nil || p[:LifesquareId] == ""
            # assignment add print request, patientid, address??? wtf bro
            # address is the ghetto riders
            # scrap the implemented code, because it's terrible
            # lsq = QrcodeController.get_assignable_code(false, patient.patient_id, address)
            # for now, inline queries, nobody was hitting it, so it was safe to put in here
            lifesquare = Lifesquare.new do |obj|
              obj.lifesquare_uid = Lifesquare.generate_code
              obj.create_user = @account.account_id
              obj.update_user = @account.account_id
              obj.valid_state = 1 # aka lifesquare.VALID
              obj.patient_id = patient.patient_id
              obj.activation_date = DateTime.now
            end
            if lifesquare.save_with_collision_detection()
              transaction[:lifesquares_generated].push(lifesquare)
            else
              # bail on errors
            end
          else
            # claim it
            lifesquare = Lifesquare.where(:lifesquare_uid => p[:LifesquareId]).first
            if lifesquare != nil and lifesquare.claimable?
              lifesquare.activation_date = DateTime.now
              lifesquare.valid_state = 1
              lifesquare.patient_id = patient.patient_id
              # THIS IS GOING TO BE DIFFICULT TO SORT OUT - unless we track some state, OH BOY SON
              # OK< discuss this use case later
              # ok, ghetto town usa, if we "had" an existing campaign, for example, use that
              # this begs the question of how we need an assigned_campaign and a user_claimed_campaign
              # ok, it's not really a big deal
              if lifesquare.save
                transaction[:lifesquares_claimed].push(lifesquare)
                # lol we don't need to print these ones son
              else
                # bail on errors
              end
            else
              # bail now
            end
          end

          coverage = Coverage.new
          coverage.patient = patient
          coverage.coverage_start = Date.today
          coverage.coverage_end = Date.today + 365
          coverage.payment = nil # this is a one to many, aka many coverages have the same payment, yea son also, it's nullable
          coverage.recurring = false
          # WHAT SON, we bailed on subscriptions one moment though
          # do we create individual subscriptions for each patient
          # or what SON, I DUNNO PUNT PUNT PUNT PUNT KICK AND PASS TIMES
          #if recurring && subscription
          #  coverage.stripe_subscription_key = subscription.id
          #end
          # this might be an error right there son
          coverage.coverage_status = 'ACTIVE'
          if coverage.save
            transaction[:coverages].push(coverage)
          end

          # then update charge meta data, son
          # ch.metadata['coverage_id'] = coverage.coverage_id
          # CreditCardService.update_charge_metadata(charge, props)

          # if we had a promo code, aka matching campaign, set on the lifesquare for attribution
          if campaign != nil
            patient.lifesquare.campaign_id = campaign.campaign_id
            patient.lifesquare.save
          end

          if credit_used
            credits_used += 1
          end

          patient.save

          # do some fancy reducer, bla bla bla or not
          printqueue = []
          transaction[:lifesquares_generated].each do |lifesquare|
            printqueue.push(lifesquare.lifesquare_uid)
          end 
          if printqueue.size > 0
            # inline-map reduce bizzle sizzle, oh my son
            printrequest = CodeSheetPrintRequest.add_new_request(printqueue.join(','), shipping_address, 0)
            transaction[:codesheetprintrequest] = printrequest
          end
        end      
      end

      # Step 2: process payment
      # TODO: check the incoming client total with the calculated total, throw an error so the client can resolve
      # for now make dummy objects for coverage, so we can test this beast son

      # if we even needed to pay because of complimentary coverage, etc
      if total_due > 0
        
        # create or obtain customer
        customer_result = init_stripe_customer(@account.this_is_me_maybe.first_name, @account.this_is_me_maybe.last_name)
        if customer_result[:success] && customer_result[:customer] != nil
          @customer = customer_result[:customer]

          # add some transaction based info to the metadata
          # all the lifesquares - we should have already grabbed this here list son
          # THIS IS JUST WRONG, but oh well here she blows
          # we could add them together then reduce, but that would be too smart™
          all_the_lifesquare_codes = []
          transaction[:lifesquares_generated].each do |lifesquare|
            all_the_lifesquare_codes.push(lifesquare.lifesquare_uid)
          end
          transaction[:lifesquares_claimed].each do |lifesquare|
            all_the_lifesquare_codes.push(lifesquare.lifesquare_uid)
          end
          @metadata['lifesquares'] = all_the_lifesquare_codes.join(',')
          @metadata['num_lifesquares'] = all_the_lifesquare_codes.size
          # man that was dirty dumplings
          
          if params[:Subscription]
            # yadda yadda yadda, it worked, or not
            description = "Lifesquares Subscription for " + all_the_lifesquare_codes.join(', ')

            # we have to bail on this part for the moment
            # do not let it pass to the bottom
            # errors.push()

            # render json: {
            #   :errors => errors,
            #   :success => false,
            #   :message => "Bad Request: Subscription Mode Not Supported"
            # }, status: 400
            # return

            # validate da subscriptions
            plan_id = nil
            plan = CreditCardService.get_plan(Rails.configuration.default_coverage_subscription)
            if plan != nil
              plan_id = plan.id
            end
            if campaign != nil
              if campaign.stripe_plan_key != nil
                # attempt to validate the plan key now
                plan = CreditCardService.get_plan(campaign.stripe_plan_key)
                if plan != nil
                  plan_id = plan.id
                end
              end
            end

            # setup our call

            if plan_id == nil
              render json: {
                # :errors => errors,
                :success => false,
                :message => "Invalid Subscription Plan"
              }, status: 500
              return
            end


            # ok, let's loop our coverages and create individual subscriptons for each
            # what is our transaction safety here, for example, if we bail, is it even remotely possible to fail on a single patient?
            # once we get this far in the process, highly unlikely
            transaction[:coverages].each do |coverage|
              # unsure of why we're gonna send the names? I don't think we really need to but it's ok I think
              # if stripe were hacked and people made sense of whatever, and whatever, the worst that would happen would be
              # public scanning access, ok, chances are 100,000,000 to 1
              # chance of getting cited in a hippa audit, slightly higher
              # TODO: revisit during pre-hippa audit
              metadata = {
                account_id: @account.uid,
                patient_id: coverage.patient.uuid,
                patient_first_name: coverage.patient.first_name,
                patient_last_name: coverage.patient.last_name,
                lifesquare_uid: coverage.patient.lifesquare.lifesquare_uid
              }
              subscription_response = CreditCardService.create_subscription(@customer.id, plan_id, 1, metadata)
              if subscription_response[:subscription]
                coverage.recurring = true
                coverage.stripe_subscription_key = subscription_response[:subscription].id
                coverage.save
                transaction[:subscriptions].push(subscription_response[:subscription])
              else
                errors.push({error: 'payment_error', message: subscription_response[:error]})
              end
              # change status to ACTIVE
              # mixin the subscription info if it exists
              # update the payment and meta information - RACE CONDITION around which object to reference here
            end

            # NOTE: we're gonna create a single Payment object here as an catch all for this transaction, lol, not that big of a deal
            # that said, it would really be x number at the individual cost, which could vary per square
            # say if you claimed one from husband health care account and wife is just signing up
            # determin what it means to be successful here

            # if transaction[:subscriptions].length == (transaction[:lifesquares_claimed].length + transaction[:lifesquares_generated].length)
            payment = Payment.new
            payment.account_id = @account.account_id
            payment.patient_id = nil
            payment.description = description
            payment.category = 'activation' # or renewal, or stickers (one-off replacements)
            payment.amount = total_due
            payment.processor = 'stripe'
            # payment.processor_payment_id = charge_response[:charge].id
            # let's really consider if we want to archive this, because it's a mild PCI issue
            # payment.processor_response = charge_response[:charge].to_json
            payment.save
            transaction[:payment] = payment

            recurring = true
            # transaction[:success] = true
            # else
              # we let it slide, and then we mop it up by cancelleing all subscriptions
            # errors.push({error: 'payment_error', message: 'Subscription Creation Failed'})
            # end
          else
            description = "Lifesquares Activation for " + all_the_lifesquare_codes.join(', ')
            # spin up that one-time charge son
            charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
            if charge_response[:success]
              transaction[:charge] = charge_response # this is just for state checking
              # now we have to support multiple payments, just null the patient_id, because I don't want to make separate partial payment objects
              payment = Payment.new
              payment.account_id = @account.account_id
              payment.patient_id = nil
              payment.description = description
              payment.category = 'activation' # or renewal, or stickers (one-off replacements)
              payment.amount = total_due
              payment.processor = 'stripe'
              payment.processor_payment_id = charge_response[:charge].id
              # let's really consider if we want to archive this, because it's a mild PCI issue
              payment.processor_response = charge_response[:charge].to_json
              payment.save
              transaction[:payment] = payment
            else
              errors.push({error: 'payment_error', message: charge_response[:error]})
              # let is continue on to catch all 402 which will show the payment error, because we have to rollback
            end
          end

          # any error condition will pass through and hit the default condition
          # establish success criteria for marking our transaction as a success
          # some dirty checking, because we don't trust all the things
          # this logic is overly complex, a payment existing will be the true indicator
          if transaction[:payment] != nil and (transaction[:charge] != nil or transaction[:subscriptions].length > 0)
            transaction[:success] = true
          end

        else
          errors.push({error: 'payment_error', message: customer_result[:error]})
        end
        
      else
        # we did not need payment, we may proceed
        transaction[:success] = true
      end

      # Step 3: commit / rollback transaction (and send notifications)
      if transaction[:success]
        # COMMIT
        # set active states toggles
        # pump the queued printing stuff down the workflow chain (to the printer) when that becomes relevant
        # update each coverage with a payment if it exists
        # update each coverage with subscription info if it exists
        # pass through to the notification part, which currently is email
        # we "need" a way to defer model post_save actions during the transaction - ask Jerry
        # however, these objects are so special, and their touchpoints are so limited
        # we could just manually invoke the pub/sub love
        # hook receipt notification(s)
        # a single bulk buy email to the account owner, plus also backend messaging entries for each patient, for status change in apps
        # pub/sub should be handled via model signals, SON
        # this particular event being perhaps elevated past the typical change event

        transaction[:lifesquares_claimed].each do |lifesquare|
          # change state to ACTIVE or whatever mumbo we need
          # trigger the next phase of QR code print bull balls, this should do our admin notifications for now
        end
        transaction[:lifesquares_generated].each do |lifesquare|
          # change state to ACTIVE or whatever mumbo we need
          # trigger the next phase of QR code print bull balls, this should do our admin notifications for now
        end
        transaction[:coverages].each do |coverage|
          # change status to ACTIVE
          # mixin the subscription info if it exists
          # update the payment and meta information - RACE CONDITION around which object to reference here
          if transaction[:payment] != nil
            coverage.payment_id = transaction[:payment].payment_id
            coverage.save
          end
        end
        transaction[:payments].each do |payment|
          # update meta data from stripers, aka the charge, or the subscription?
          # add related coverage
          # add w/e we needed
          # RACE CONDITION around which object to reference here
        end

        # remove the credits though
        if credit_used && credits_used > 0
          # here goes nothing
          campaign.lifesquare_credits -= credits_used
          campaign.save
        end

        begin
          notification = "Lifesquares successfully assigned!"
          if transaction[:payment] != nil
            notification = "Payment successful and Lifesquares assigned!" 
          end
          if transaction[:lifesquares_generated].length > 0
            notification = notification + " Your stickers should arrive in the next 7-10 days."
          end
          flash[:notice] = notification
        rescue

        end
        
        email = @account.email
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          # TODO: dynamic title
          # TODO: sort template it's bogus
          # TODO: maually merge in content from the stickers email, which talks about shipping expectations
          # TODO: BEAST MODE ON THAT BIZZLE and we could do a shipping API integration for tracking codes n such, which we should do

          AccountMailer.send_email(
            email,
            "Lifesquare coverage activated",
            'patients/mailer/assign_receipt',
            {
              :payment => transaction[:payment],
              :coverages => transaction[:coverages],
              :account => @account,
              :recurring => recurring,
              :generated => transaction[:lifesquares_generated]
            }
            ).deliver_later(wait: 1.minute)
        end
        # admin / customer support notifications should have occurred with the QR code controller stuffs
      else
        rollback_assign_transaction(transaction)

        # TODO: if we're magical, we would check the errors for payment errors, and send an appropriate header 402
        payment_errors = false
        errors.each do |e|
          if e[:error] == "payment_error"
            payment_errors = true
          end
        end

        if payment_errors
          render json: {
            :errors => errors,
            :success => false,
            :message => "Bad Request: Payment Errors"
          }, status: 402
          return
        end

        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Multiple Errors"
        }, status: 400
        return

      end

      # Step 4: return response to client, if we haven't already bailed
      render json: {
        :success => true,
        :message => "Lifesquare(s) created and coverage(s) activated"
      }, status: 200
      # nothing left to do… all done
    end

    def validate
      # do literally all the things at once
      # the logic is gonna be basically shared here, between the two,
      # differences being returning pricing information and errors, vs processing and success 

      # TODO: reject on duplicates

      # {
      #   Patients: [
      #     { 
      #       PatientId: "1239018231908210381309183",
      #       LifesquareId: null, LifesquareId: "", or missing LifesquareId… oh yea son
      #     },
      #     { 
      #       PatientId: "1239018231908210381309185",
      #       LifesquareId: "ABC123ABC"
      #     }
      #   ],
      #   Shipping: {
      #      Address: 102920,
      #   },
      #   Promo: "cheaptimes",
      #   Subscription: true,
      #   Payment: null
      # }
      r = {
        :Patients => []
      }
      total_due = 0
      costs = []
      # DRY UP THIS LEDGER CALC
      cost_per_lifesquare = Rails.configuration.default_coverage_cost
      if params[:PromoCode].length > 0
        campaign = find_campaign_with_promo(params[:PromoCode])
        if campaign != nil
          cost_per_lifesquare = campaign.promo_price
          # TODO revisit this if in some basic conditions, such as single patient, and campaign price is in fact less than
          # but for now, go ahead and crank it down, just for kicks to the lowest possible price
          # TODO: REVISIT THIS SON

          # TODO: blocking on code based on lacking credits, although, hmm, that's a bad news scenario, I say, we let it through so things can associated
          # negative credits should be billed to the organization each month with a report

          r[:Promo] = {
            :Code => campaign.promo_code,
            :Price => campaign.promo_price,
            :Valid => true
          }
          costs.append(campaign.promo_price)
        else
          r[:Promo] = {
            :Code => params[:PromoCode],
            :Valid => false
          }
        end
      end
      validated_codes = []
      
      params[:Patients].each do |p|
        # we're pretty darn sure it's a valid patient, but just in case
        # for now require owner
        # bombs if not owner, but that should never happen and will catch a 500
        # TODO: accept that we no longer need an "active" patient because of revised onboarding states and flows
        patient = Patient.where(:account_id => @account.account_id, :uuid => p[:PatientId]).first
        lifesquare_id = nil
        unit_cost = cost_per_lifesquare
        valid = false
        message = nil
        sponsoring_org = nil
        
        if p[:LifesquareId] != nil && p[:LifesquareId] != ""
          lifesquare = Lifesquare.where(:lifesquare_uid => p[:LifesquareId]).first
          lifesquare_id = p[:LifesquareId]
          if lifesquare != nil and lifesquare.claimable?
            # now… look up dat cost to see what kind of pricey price we might have
            lifesquare_id = lifesquare.lifesquare_uid
            if validated_codes.include? lifesquare.lifesquare_uid
              valid = false
              message = 'Duplicate Code'
            else
              validated_codes.append lifesquare.lifesquare_uid
              valid = true
              if lifesquare.campaign != nil
                if lifesquare.campaign.organization != nil
                  sponsoring_org = lifesquare.campaign.organization.name
                end
                if cost_per_lifesquare > lifesquare.campaign.user_shared_cost_for_campaign
                  unit_cost = lifesquare.campaign.user_shared_cost_for_campaign
                end
              end
            end
          end
        end
        
        total_due += unit_cost
        # TODO: cost hack
        costs.append(unit_cost)

        # ugg this syntax bro
        r[:Patients].append({
          :PatientId => patient.uuid,
          :LifesquareId => lifesquare_id,
          :Valid => valid,
          :Message => message,
          :UnitCost => unit_cost,
          :SponsoringOrg => sponsoring_org
        })

      end

      r[:Total] = total_due

      # TODO: temp hack to display silly promos that were more expensive than the unit cost
      # so people aren't confused
      if r[:Promo] != nil && r[:Promo][:Valid]
        r[:Promo][:Price] = costs.min
      end
      
      render json: r, status: 200
    end

    def replace
      # sending the lifesquare is redundant, but let's send it anyhow
      # {
      #   Patients: [
      #     { 
      #       PatientId: "1239018231908210381309183",
      #     },
      #     { 
      #       PatientId: "1239018231908210381309185",
      #     }
      #   ],
      #   Shipping: {
      #      ResidenceId: 102920,
      #   },
      #   Payment: {
      #     CardId: "12311231131",
      #     Token: "aadwaukdakuywad3aukhawkdha"
      #   }
      # }

      # Much of the meat and potatoes of this implementation is the same as /assign but we will leave it discreet for now!
      total_due = 0
      unit_cost = Rails.configuration.default_replacement_sticker_cost

      # TODO: promotional bits n bobs, or something that might have enterprise billing, etc
      # this is only end-user billing now
      errors = []
      transaction = {
        :success => false,
        # do we even need the actual lifesquares, nope, except it will make for a convenient receipt iteration
        :lifesquares => [],
        :charge => nil,
        :payment => nil, # our record of the one time fee, hmm, we will need one for each subscription though
        :codesheetprintrequest => nil
      }

      residence = PatientResidence.where(:patient_residence_id => params[:Shipping][:ResidenceId]).first
      if residence == nil
        errors.push({
          error: 'invalid_address',
          message: "Invalid Shipping Address"
        })
        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Invalid Address"
        }, status: 400
        return
      else
        # you may ask we we both, vs passing a residence instance, beats me,
        # maybe we can optimize this later
        address = {
          :address_line1 => residence.address_line1,
          :address_line2 => residence.address_line2,
          :address_line3 => residence.address_line3,
          :city => residence.city,
          :state_province => residence.state_province,
          :postal_code => residence.postal_code,
          :country => residence.country
        }
      end

      # this is really really really really really verbose and sloppy but it gets the job done
      params[:Patients].each do |p|
        patient = Patient.where(:uuid => p[:PatientId]).first
        if patient == nil
          render json: {
            :errors => errors,
            :success => false,
            :message => "Invalid Lifesquare"
          }, status: 400
          return
        else
          # TODO: onsider dem sticker credits on the "active coverage" for each patient, bro
          # feature was kinda half-baked and has no UI manifestation so, just punt now
          
          # queue da print request
          # but what canonical business is this for realsies
          lifesquare = Lifesquare.where(:patient_id => patient.patient_id, :valid_state => 1).first
          if lifesquare == nil
            render json: {
              :errors => errors,
              :success => false,
              :message => "Invalid Lifesquare"
            }, status: 400
          return
          else
            transaction[:lifesquares].push(lifesquare)
            total_due += unit_cost
          end
        end
      end

      # do the optimistic part, aka create the print request
      # oh yea, read up on map/reduce in ruby
      printqueue = []
      transaction[:lifesquares].each do |lifesquare|
        printqueue.push(lifesquare.lifesquare_uid)
      end 
      if printqueue.size > 0
        # inline-map reduce bizzle sizzle, oh my son
        printrequest = CodeSheetPrintRequest.add_new_request(printqueue.join(','), address, 0)
        transaction[:codesheetprintrequest] = printrequest
      end

      # payment
      if total_due > 0
        # we are only a direct payment, so just get that out of the way

        # create or obtain customer
        customer_result = init_stripe_customer(@account.this_is_me_maybe.first_name, @account.this_is_me_maybe.last_name)
        if customer_result[:success] && customer_result[:customer] != nil
          @customer = customer_result[:customer]

          @metadata['lifesquares'] = printqueue.join(',')
          @metadata['num_lifesquares'] = printqueue.size

          description = "Replacement Lifesquares for " + printqueue.join(', ')
          # spin up that one-time charge son
          charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
          if charge_response[:success]
            transaction[:charge] = charge_response # this is just for state checking
            # now we have to support multiple payments, just null the patient_id, because I don't want to make separate partial payment objects
            payment = Payment.new
            payment.account_id = @account.account_id
            payment.patient_id = nil
            payment.description = description
            payment.category = 'stickers' # or renewal, or stickers (one-off replacements)
            payment.amount = total_due
            payment.processor = 'stripe'
            payment.processor_payment_id = charge_response[:charge].id
            # let's really consider if we want to archive this, because it's a mild PCI issue
            payment.processor_response = charge_response[:charge].to_json
            payment.save
            transaction[:payment] = payment
          else
            errors.push({error: 'payment_error', message: charge_response[:error]})
            # let is continue on to catch all 402 which will show the payment error, because we have to rollback
          end

          if transaction[:payment] != nil and transaction[:charge] != nil
            transaction[:success] = true
          end

        else
          errors.push({error: 'payment_error', message: customer_result[:error]})
        end

      else

        # somehow we might be credited, so we'll magically say the transaction was good
        transaction[:success] = true

      end

      # Step 3: process transaction
      if transaction[:success]

        # bump coverages out?
        # this was in the original, but unsure
        begin
          if transaction[:payment] != nil
            flash[:notice] = 'Payment successful! Your replacement stickers should arrive in the next 7-10 days.'
          else
            flash[:notice] = 'Your replacement stickers should arrive in the next 7-10 days.'
          end
        rescue
        end

        email = @account.email
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          # TODO: dynamic title
          # TODO: sort template it's bogus
          # TODO: maually merge in content from the stickers email, which talks about shipping expectations
          # TODO: BEAST MODE ON THAT BIZZLE and we could do a shipping API integration for tracking codes n such, which we should do

          AccountMailer.send_email(
            email,
            "Replacement Lifesquares ordered",
            'patients/mailer/replace_receipt',
            {
              :lifesquares => transaction[:lifesquares],
              :payment => transaction[:payment],
              :account => @account,
            }
            ).deliver_later(wait: 1.minute)
        end


      else

        # TODO: rollback coverage to original enddate
        # but we haven't extended it yet
        # this is just not going to be the case, but anyhow
        if transaction[:payment] != nil
          # transaction[:payment].destroy
          # TODO: send an admin email if we failed the transaction but the user paid
        end
        if transaction[:codesheetprintrequest] != nil
          transaction[:codesheetprintrequest].destroy
        end

        # TODO: if we're magical, we would check the errors for payment errors, and send an appropriate header 402
        payment_errors = false
        errors.each do |e|
          if e[:error] == "payment_error"
            payment_errors = true
          end
        end

        if payment_errors
          render json: {
            :errors => errors,
            :success => false,
            :message => "Bad Request: Payment Errors"
          }, status: 402
          return
        end
        
        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Multiple Errors"
        }, status: 400
        return

      end

      # send messaging / notifications
      

      # return a response to the client
      render json: {
        :success => true,
        :message => "Replacement Lifesquare(s) queued"
      }, status: 200
    end

    def renew
      # TODO: refactor into generic checkout cart processor
      # {
      #   Patients: [
      #     { 
      #       PatientId: "1239018231908210381309183",
      #     },
      #     { 
      #       PatientId: "1239018231908210381309185",
      #     }
      #   ],
      #   Shipping: {
      #      ResidenceId: 102920,
      #   },
      #   Payment: {
      #     CardId: "12311231131",
      #     Token: "aadwaukdakuywad3aukhawkdha"
      #   }
      # }

      # transaction model of the other endpoints for consistency
      errors = []
      
      transaction = {
        :success => false,
        # these are references to objects so we can roll them back if needed
        # double check which of these objects sets attributes on their 1:1 patient, if any
        :charge => nil, # one time fee, costco bulk times, there can only ever be one? I think
        :subscriptions => [], # we have to spin up 1 per patient, lulz
        :payments => [], # our record of the one time fee, hmm, we will need one for each subscription though
        :coverages => [],
        :codesheetprintrequest => nil
        # it doesn't seem like we can actually pause the delivery of the notification objects, uggg, lol, look into that
        # however, we have a high degree of success with pre-validation, and using existing stripe info or a valid pre-tokenized card
      }

      total_due = 0
      recurring = false # not part of the transaction, part of state

      residence = PatientResidence.where(:patient_residence_id => params[:Shipping][:ResidenceId]).first
      if residence == nil
        errors.push({
          error: 'invalid_address',
          message: "Invalid Shipping Address"
        })
        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Invalid Address"
        }, status: 400
        return
      else
        # you may ask we we both, vs passing a residence instance, beats me,
        # maybe we can optimize this later
        address = {
          :address_line1 => residence.address_line1,
          :address_line2 => residence.address_line2,
          :address_line3 => residence.address_line3,
          :city => residence.city,
          :state_province => residence.state_province,
          :postal_code => residence.postal_code,
          :country => residence.country
        }
      end

      all_the_lifesquare_codes = []

      params[:Patients].each do |p|
        # we're pretty darn sure it's a valid patient, but just in case
        # for now require owner
        # bombs if not owner, but that should never happen and will catch a 500
        patient = Patient.where(:account_id => @account.account_id, :uuid => p[:PatientId], :status => 'ACTIVE').first          
        if patient.lifesquare != nil
          total_due += patient.coverage_cost
          all_the_lifesquare_codes.push(patient.lifesquare.lifesquare_uid)
          coverage = Coverage.new
          coverage.patient = patient
          coverage.coverage_start = Date.today
          coverage.coverage_end = Date.today + 365
          coverage.payment = nil # this is a one to many, aka many coverages have the same payment, yea son also, it's nullable
          coverage.recurring = false
          coverage.coverage_status = 'ACTIVE'
          if coverage.save
            transaction[:coverages].push(coverage)
          end
        else
          render json: {
            :success => false,
            :message => "Bad Request: Invalid Lifesquares"
          }, status: 400
          return
        end

        # did we need to printqueue the lifesquares or are we hitting up the bonus bin

      end

      if total_due > 0
        
        # create or obtain customer
        customer_result = init_stripe_customer(@account.this_is_me_maybe.first_name, @account.this_is_me_maybe.last_name)
        if customer_result[:success] && customer_result[:customer] != nil
          @customer = customer_result[:customer]

          # add some transaction based info to the metadata
          # all the lifesquares - we should have already grabbed this here list son
          # THIS IS JUST WRONG, but oh well here she blows
          # we could add them together then reduce, but that would be too smart™
          
          
          # build this out of the patients
          
          @metadata['lifesquares'] = all_the_lifesquare_codes.join(',')
          @metadata['num_lifesquares'] = all_the_lifesquare_codes.size
          # man that was dirty dumplings
          
          if params[:Subscription]
            # yadda yadda yadda, it worked, or not
            description = "Lifesquares Subscription for " + all_the_lifesquare_codes.join(', ')

            # we have to bail on this part for the moment
            # do not let it pass to the bottom
            # errors.push()

            # render json: {
            #   :errors => errors,
            #   :success => false,
            #   :message => "Bad Request: Subscription Mode Not Supported"
            # }, status: 400
            # return

            # validate da subscriptions
            plan_id = nil
            plan = CreditCardService.get_plan(Rails.configuration.default_coverage_subscription)
            if plan != nil
              plan_id = plan.id
            end

            # coverage campaign on the lifesquare
            """
            if campaign != nil
              if campaign.stripe_plan_key != nil
                # attempt to validate the plan key now
                plan = CreditCardService.get_plan(campaign.stripe_plan_key)
                if plan != nil
                  plan_id = plan.id
                end
              end
            end
            """

            # setup our call

            if plan_id == nil
              render json: {
                # :errors => errors,
                :success => false,
                :message => "Invalid Subscription Plan"
              }, status: 500
              return
            end


            # ok, let's loop our coverages and create individual subscriptons for each
            # what is our transaction safety here, for example, if we bail, is it even remotely possible to fail on a single patient?
            # once we get this far in the process, highly unlikely
            transaction[:coverages].each do |coverage|
              # unsure of why we're gonna send the names? I don't think we really need to but it's ok I think
              # if stripe were hacked and people made sense of whatever, and whatever, the worst that would happen would be
              # public scanning access, ok, chances are 100,000,000 to 1
              # chance of getting cited in a hippa audit, slightly higher
              # TODO: revisit during pre-hippa audit
              metadata = {
                account_id: @account.uid,
                patient_id: coverage.patient.uuid,
                patient_first_name: coverage.patient.first_name,
                patient_last_name: coverage.patient.last_name,
                lifesquare_uid: coverage.patient.lifesquare.lifesquare_uid
              }
              subscription_response = CreditCardService.create_subscription(@customer.id, plan_id, 1, metadata)
              if subscription_response[:success]
                coverage.recurring = true
                coverage.stripe_subscription_key = subscription_response[:subscription].id
                coverage.save
                transaction[:subscriptions].push(subscription_response[:subscription])
              else
                errors.push({error: 'payment_error', message: subscription_response[:error]})
              end
              # change status to ACTIVE
              # mixin the subscription info if it exists
              # update the payment and meta information - RACE CONDITION around which object to reference here
            end

            # NOTE: we're gonna create a single Payment object here as an catch all for this transaction, lol, not that big of a deal
            # that said, it would really be x number at the individual cost, which could vary per square
            # say if you claimed one from husband health care account and wife is just signing up
            # determin what it means to be successful here

            # if transaction[:subscriptions].length == (transaction[:lifesquares_claimed].length + transaction[:lifesquares_generated].length)
            payment = Payment.new
            payment.account_id = @account.account_id
            payment.patient_id = nil
            payment.description = description
            payment.category = 'activation' # or renewal, or stickers (one-off replacements)
            payment.amount = total_due
            payment.processor = 'stripe'
            # payment.processor_payment_id = charge_response[:charge].id
            # let's really consider if we want to archive this, because it's a mild PCI issue
            # payment.processor_response = charge_response[:charge].to_json
            payment.save
            transaction[:payment] = payment

            recurring = true
            # transaction[:success] = true
            # else
              # we let it slide, and then we mop it up by cancelleing all subscriptions
              # errors.push({error: 'payment_error', message: 'Subscription Creation Failed'})
            # end
          else
            description = "Lifesquares Activation for " + all_the_lifesquare_codes.join(', ')
            # spin up that one-time charge son
            charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
            if charge_response[:success]
              transaction[:charge] = charge_response # this is just for state checking
              # now we have to support multiple payments, just null the patient_id, because I don't want to make separate partial payment objects
              payment = Payment.new
              payment.account_id = @account.account_id
              payment.patient_id = nil
              payment.description = description
              payment.category = 'activation' # or renewal, or stickers (one-off replacements)
              payment.amount = total_due
              payment.processor = 'stripe'
              payment.processor_payment_id = charge_response[:charge].id
              # let's really consider if we want to archive this, because it's a mild PCI issue
              payment.processor_response = charge_response[:charge].to_json
              payment.save
              transaction[:payment] = payment
            else
              errors.push({error: 'payment_error', message: charge_response[:error]})
              # let is continue on to catch all 402 which will show the payment error, because we have to rollback
            end
          end

          # any error condition will pass through and hit the default condition
          # establish success criteria for marking our transaction as a success
          # some dirty checking, because we don't trust all the things
          # this logic is overly complex, a payment existing will be the true indicator
          if transaction[:payment] != nil and (transaction[:charge] != nil or transaction[:subscriptions].length > 0)
            transaction[:success] = true
          end


        else
          errors.push({error: 'payment_error', message: customer_result[:error]})
        end

        
      else
        # we did not need payment, we may proceed
        transaction[:success] = true
      end

      # Step 3: commit / rollback transaction (and send notifications)
      if transaction[:success]
        
        transaction[:coverages].each do |coverage|
          # change status to ACTIVE
          # mixin the subscription info if it exists
          # update the payment and meta information - RACE CONDITION around which object to reference here
          if transaction[:payment] != nil
            coverage.payment_id = transaction[:payment].payment_id
            coverage.save
          end
        end
        transaction[:payments].each do |payment|
          # update meta data from stripers, aka the charge, or the subscription?
          # add related coverage
          # add w/e we needed
          # RACE CONDITION around which object to reference here
        end

        # TODO: for now spin up flash
        begin
          if transaction[:payment] != nil
            flash[:notice] = 'Payment successful and Lifesquares renewed!'
          else
            flash[:notice] = 'Lifesquares successfully renewed!'
          end
        rescue

        end
        
        email = @account.email
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          # TODO: dynamic title
          # TODO: sort template it's bogus
          # TODO: maually merge in content from the stickers email, which talks about shipping expectations
          # TODO: BEAST MODE ON THAT BIZZLE and we could do a shipping API integration for tracking codes n such, which we should do

          AccountMailer.send_email(
            email,
            "Lifesquare coverage activated",
            'patients/mailer/renew_receipt',
            {
              :payment => transaction[:payment],
              :coverages => transaction[:coverages],
              :account => @account,
              :recurring => recurring
            }
            ).deliver_later(wait: 1.minute)
        end
        # admin / customer support notifications should have occurred with the QR code controller stuffs
      else

        # ROLLBACK
        # hopefully this doesn't cluster fire bomb us with cascade delete hell
        # don't think we have any "managed attributes" on the patient, but if we did, reset them
        # remove all objects we created
        transaction[:coverages].each do |coverage|
          # delete each one
          coverage.destroy
          # be sure to have patient reference updated
        end
        transaction[:subscriptions].each do |subscription|
          # delete each one
          # payment.destroy
          cancelled = CreditCardService.cancel_subscription(customer_id, subscription.id)
          # trigger a note to admins / customer support to check and mop this up if needed
        end
        transaction[:payments].each do |payment|
          # delete each one
          payment.destroy
        end

        if transaction[:codesheetprintrequest] != nil
          transaction[:codesheetprintrequest].destroy
        end

        # TODO: if we're magical, we would check the errors for payment errors, and send an appropriate header 402
        payment_errors = false
        errors.each do |e|
          if e[:error] == "payment_error"
            payment_errors = true
          end
        end

        if payment_errors
          render json: {
            :errors => errors,
            :success => false,
            :message => "Bad Request: Payment Errors"
          }, status: 402
          return
        end

        render json: {
          :errors => errors,
          :success => false,
          :message => "Bad Request: Multiple Errors"
        }, status: 400
        return
      end

      # Step 4: return response to client, if we haven't already bailed
      render json: {
        :success => true,
        :message => "Lifesquare coverage(s) renewed"
      }, status: 200
      # nothing left to do… all done
    end

    # Operations
    # create a batch - aka, cook up a series of lifesquares, and create a print request for them
    def create_batch
      # this kinda does belong here
      # endpoint from the companion get form in the admin son
      # {
      #   BatchSize: 0-100
      #   Notes: "hotmess"
      #   CampaignId: 10
      # }
      batch = LifesquareCodeBatch.create(
        :batch_size => params[:BatchSize].to_i,
        :notes => params[:Notes]
      )
      batch.save
      if batch.provision_lifesquares(@account.account_id, params[:CampaignId])
        render json: {
          :success => true,
          :message => "Batch Cooked"
        }, status: 200
      end
    end

  private

    def format_residence_json(residence)
      # TODO: move to a model method, yea
      location = ''
      if residence[:lifesquare_location_type] == "lsq_location_other"
        location = residence.lifesquare_location_other
      elsif residence[:lifesquare_location_type] != ""
        begin
          location = PatientResidence.lifesquare_location_types[residence[:lifesquare_location_type]]# LifesquareLocationType.where(:lifesquare_location_type => residence.lifesquare_location_type).first.user_mask
        rescue
        end
      end

      # TODO: iOS is barfing on null in some cases on address2 and location
      address2 = residence.address_line2
      if location == nil
        location = ''
      end
      if address2 == nil
        address2 = ''
      end

      return {
        :Address1 => residence.address_line1,
        :Address2 => address2,
        :City => residence.city,
        :State => residence.state_province,
        :Postal => residence.postal_code,
        :Latitude => residence.latitude,
        :Longitude => residence.longitude,
        :LifesquareLocation => location
      }
    end

    def format_provider_lifesquare_json(patient, residence=nil, latitude=nil, longitude=nil)
      # this is the really highlevel info returning from searching or geo queries, it DOES NOT include the lifesquare ID
      #
      # arguments either a lifesquare_uid or a patient_id

      # query the primary patient residence if it is available to show the lifesquare location, OH YEA

      # decorate with geo distance logic

      # BUT, we should be using an annotated query from original query

      distance = nil
      if residence and latitude and longitude
        # fraction of mile, to
        begin
          d1 = residence.distance_to([latitude, longitude])
          distance = (d1 * 1609.344).round
        rescue
          # we're geocoding busted so horribly, probably from a crappy data input for address
        end
      end

      residence_json = nil

      # TODO: full auth check, but really, really, shouldn't we have done it prior, depends on our privacy toggle
      if residence and ['provider', 'public'].include? residence.privacy
        residence_json = format_residence_json(residence)
      end

      return_json = {
        :FirstName => patient.first_name,
        :LastName => patient.last_name,
        :Photo => patient_photo(patient, request), # old attribute
        :ProfilePhoto => patient_photo(patient, request),
        :Distance => distance
      }

      if residence_json
        return_json[:Residence] = residence_json
      end

      return return_json
    end

    def rollback_assign_transaction(transaction)
      # ROLLBACK
      # hopefully this doesn't cluster fire bomb us with cascade delete hell
      # don't think we have any "managed attributes" on the patient, but if we did, reset them
      # remove all objects we created
      transaction[:lifesquares_claimed].each do |lifesquare|
        # de-allocate each one
        lifesquare.patient_id = nil
        lifesquare.activation_date = nil
        lifesquare.valid_state = 0
        lifesquare.save
        # be sure to have patient reference updated
      end
      transaction[:lifesquares_generated].each do |lifesquare|
        # de-allocate each one
        lifesquare.destroy
        # be sure to have patient reference updated
      end
      transaction[:coverages].each do |coverage|
        # delete each one
        coverage.destroy
        # be sure to have patient reference updated
      end
      transaction[:subscriptions].each do |subscription|
        # delete each one
        # payment.destroy
        cancelled = CreditCardService.cancel_subscription(customer_id, subscription.id)
        # trigger a note to admins / customer support to check and mop this up if needed
      end
      transaction[:payments].each do |payment|
        # delete each one
        payment.destroy
      end

      if transaction[:codesheetprintrequest] != nil
        transaction[:codesheetprintrequest].destroy
      end
    end


  end
end
