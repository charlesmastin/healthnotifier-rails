module Api
  class OrganizationsController < Api::ApplicationController
    before_action :authenticate_account
    before_action :obtain_organization

    def order_lifesquares
      # AT THE MOMENT… NO STICKER ORDERING, JUST PRE_PAY
      # look it up bro brizzle
      # Quantity
      # Payment info as per usual brizzle
      # special email "invoice as paid though"
      # provision an allotment though, aka, something
      # transaction code though bro
      errors = []
      transaction = {
        :success => false,
        :charge => nil,
        :payment => nil,
        :organization => @organization,
        :quantity => params[:Quantity]
      }
      total_due = params[:Quantity] * @organization.get_coverage_cost
      if total_due > 0
        customer_result = init_stripe_customer(@organization.contact_first_name, @organization.contact_last_name)
        if customer_result[:success] && customer_result[:customer] != nil
          @customer = customer_result[:customer]

          campaign = Campaign.create()
          campaign.name = "#{Date.today.to_date.strftime('%Y-%m-%d')} - Prepay (#{transaction[:quantity]})"
          campaign.description = ""
          campaign.create_user = @account.account_id
          campaign.update_user = @account.account_id
          campaign.start_date = Date.today
          campaign.end_date = Date.today + 365
          campaign.organization_id = @organization.organization_id
          campaign.set_random_promo_code
          campaign.promo_price = 0
          campaign.promo_start_date = Date.today.to_date
          campaign.promo_end_date = (Date.today + 365).to_date
          campaign.lifesquare_credits = transaction[:quantity]

          if campaign.save

            @metadata['organization_id'] = @organization.organization_id
            @metadata['campaign_id'] = campaign.campaign_id
            @metadata['num_lifesquares'] = params[:Quantity]

            description = "Prepay Lifesquares for " + @organization.name
            # spin up that one-time charge son
            charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
            if charge_response[:success]
              transaction[:charge] = charge_response # this is just for state checking
              # now we have to support multiple payments, just null the patient_id, because I don't want to make separate partial payment objects
              payment = Payment.new
              payment.account_id = @account.account_id
              payment.patient_id = nil
              payment.description = description
              payment.category = 'credits' # or renewal, or stickers (one-off replacements)
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

              # email to account owners - invoice "receipt", w/ promo code
              AccountMailer.send_email(
                @account.email,
                "Prepay Lifesquares Receipt",
                'organizations/mailer/order_lifesquares_receipt',
                {
                  :quantity => transaction[:quantity],
                  :unit_cost => @organization.get_coverage_cost,
                  :payment => transaction[:payment],
                  :organization => @organization,
                  :campaign => campaign,
                  :account => @account
                }
              ).deliver_later
              # email to lifesquare admins

              # comedy times for the existing web clients
              begin
                flash[:notice] = 'Order processed! Please check your email for a receipt.'
              rescue
              end

              render json: {
                :success => true,
                :message => "Prepay ALL THE THINGS!"
              }, status: 200
              return

            end

          else
            byebug
          end

        else
          errors.push({error: 'payment_error', message: customer_result[:error]})
        end

        # undo our crap


      else
        render json: {
          :errors => nil,
          :success => false,
          :message => "Bad Request: Quantity Required"
        }, status: 400
      end
    end

    def renew_lifesquares
      patients = []
      excluded_patient_uuids = params[:Exclusions]
      @organization.get_patients().each do |patient|
        append = true
        if excluded_patient_uuids.include? patient.uuid
          append = false
          # do something with it though???
        end
        if append
          patients.append(patient)
        end
      end

      # transaction approach though
      errors = []
      
      transaction = {
        :success => false,
        :charge => nil, # one time fee, costco bulk times, there can only ever be one? I think
        :payments => [], # our record of the one time fee, hmm, we will need one for each subscription though
        :coverages => [],
        :codesheetprintrequest => nil
      }

      total_due = 0
      all_the_lifesquare_codes = []

      patients.each do |patient|
        # with all the whitelisted, bump their coverage +1 year from coverage end
        total_due += @organization.get_coverage_cost()
        all_the_lifesquare_codes.push(patient.lifesquare.lifesquare_uid)
        start_date = Date.today
        end_date = Date.today + 365
        if patient.current_coverage
          end_date = patient.current_coverage.coverage_end + 365
        end
        coverage = Coverage.new
        coverage.patient = patient
        coverage.coverage_start = start_date
        coverage.coverage_end = end_date
        coverage.payment = nil # this is a one to many, aka many coverages have the same payment, yea son also, it's nullable
        coverage.recurring = false
        coverage.coverage_status = 'ACTIVE'
        if coverage.save
          transaction[:coverages].push(coverage)
        end
      end

      if total_due > 0

        # attempt dat payment son
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
          @metadata['organization'] = @organization.uuid

          description = "Org Lifesquares Renewal:" + @organization.uuid
          # spin up that one-time charge son
          charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
          if charge_response[:success]
            transaction[:charge] = charge_response # this is just for state checking
            # now we have to support multiple payments, just null the patient_id, because I don't want to make separate partial payment objects
            payment = Payment.new
            payment.account_id = @account.account_id
            payment.patient_id = nil
            payment.description = description
            payment.category = 'renewal' # or renewal, or stickers (one-off replacements)
            payment.amount = total_due
            payment.processor = 'stripe'
            payment.processor_payment_id = charge_response[:charge].id
            # let's really consider if we want to archive this, because it's a mild PCI issue
            payment.processor_response = charge_response[:charge].to_json
            payment.save
            transaction[:payment] = payment

            # go through the things, reassociate the bits and bobts
            transaction[:coverages].each do |coverage|
              # change status to ACTIVE
              # mixin the subscription info if it exists
              # update the payment and meta information - RACE CONDITION around which object to reference here
              if transaction[:payment] != nil
                coverage.payment_id = transaction[:payment].payment_id
                coverage.save
              end
            end

            transaction[:success] = true

          else
            errors.push({error: 'payment_error', message: charge_response[:error]})
            # let is continue on to catch all 402 which will show the payment error, because we have to rollback
          end
        end
      end


      # if if fails at all, undo the transaction
      if transaction[:success]
        begin
          flash[:notice] = "Order processed for #{patients.count} renewals! Please check your email for a receipt."
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
              :recurring => false
            }
            ).deliver_later
        end

        render json: {
          :success => true,
          :message => "Prepay ALL THE THINGS!"
        }, status: 200
      else

        # roll-it-back-bro
        transaction[:coverages].each do |coverage|
          # delete each one
          coverage.destroy
          # be sure to have patient reference updated
        end
        # huh?
        transaction[:payments].each do |payment|
          # delete each one
          payment.destroy
        end

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

      end
    end

    def charge_invoice
      # QND son
      invoice = Invoice.where(:uuid=>params[:invoice_uuid]).first
      if invoice != nil && invoice.payment != nil
        render json: {
          :errors => errors,
          :success => false,
          :message => "Invoice alredy paid!"
        }, status: 404
      end
      errors = []
      transaction = {
        :success => false,
        :charge => nil, # one time fee, costco bulk times, there can only ever be one? I think
        :payment => nil # our record of the one time fee, hmm, we will need one for each subscription though        
      }
      total_due = invoice.amount

      # FIXME: we need the fake patient to stub the account owners name here… unless we desire to pass in billing details from a form though
      customer_result = init_stripe_customer(@account.this_is_me_maybe.first_name, @account.this_is_me_maybe.last_name)
      if customer_result[:success] && customer_result[:customer] != nil
        @customer = customer_result[:customer]          
        @metadata['invoice'] = invoice.uuid
        @metadata['organization'] = @organization.uuid
        description = "Invoice:" + invoice.uuid
        charge_response = CreditCardService.charge(@customer.id, total_due, description, @metadata)
        if charge_response[:success]
          transaction[:charge] = charge_response
          payment = Payment.new
          payment.account_id = @account.account_id
          payment.patient_id = nil
          payment.description = description
          payment.category = 'invoice' # or renewal, or stickers (one-off replacements)
          payment.amount = total_due
          payment.processor = 'stripe'
          payment.processor_payment_id = charge_response[:charge].id
          # let's really consider if we want to archive this, because it's a mild PCI issue
          payment.processor_response = charge_response[:charge].to_json
          payment.save
          invoice.payment_id = payment.payment_id
          invoice.save
          transaction[:payment] = payment
          transaction[:success] = true
        else
          errors.push({error: 'payment_error', message: charge_response[:error]})
          # let is continue on to catch all 402 which will show the payment error, because we have to rollback
        end
      end

      if transaction[:success]
        begin
          flash[:notice] = "Invoice processed! Please check your email for a receipt."
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
            "Lifesquare invoice paid - #{invoice.uuid}",
            'organizations/mailer/charge_invoice_receipt',
            {
              :payment => transaction[:payment],
              :invoice => invoice,
              :account => @account
            },
            ["charles@lifesquare.com"] # TODO: a general billing@lifesquare.com address though
            ).deliver_later
        end

        render json: {
          :success => true,
          :message => "Prepay ALL THE THINGS!"
        }, status: 200
      else

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

      end
    end

    def notify_invoice
      invoice = Invoice.where(:uuid=>params[:invoice_uuid]).first
      if invoice != nil && invoice.payment != nil
        render json: {
          :errors => errors,
          :success => false,
          :message => "Invoice alredy paid!"
        }, status: 404
        return
      end
      # grab dem org, owners, and admins son, iterate on dat shee shee shee because why not den
      AccountMailer.send_email(
        "charles+org3@lifesquare.com",
        "Lifesquare Invoice - #{invoice.uuid}",
        'organizations/mailer/invoice',
        {
          :organization => @organization,
          :invoice => invoice,
          :account => @account
        },
        ["charles@lifesquare.com"] # TODO: a general billing@lifesquare.com address though
        ).deliver_later

      # TODO: set last_notified_at timestamp though
      render json: {
        :success => true,
        :message => "Contacts notified"
      }, status: 200

    end

    def member_search
      # TODO: scoped permissions based on user
      # handle org scope
      # TODO: as we open this up for more purposes
      # we will need to return deleted patients and mark them as such in the UI... mmmkay      
      words = params[:keywords].split(' ') # this bombs on certain email lookups, we need better logic
      patients = []
      # we're DAMN specific here, so it's way too much effort to go into the general patient search and branch the code
      account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", params[:keywords].downcase).first
      if account != nil
        for patient in account.active_patients
          if patient.organization == @organization
            patients.append(patient)
          end
        end
      end

      # match on lifesquare number, yea son
      lifesquare = Lifesquare.where(:lifesquare_uid => params[:keywords].upcase).first
      if lifesquare != nil
        if lifesquare.patient != nil && lifesquare.patient.organization == @organization
          patients.append(lifesquare.patient)
        end
      end

      if words.length == 2
        results = Patient.where("lower(first_name) = ? AND lower(last_name) = ? AND status = 'ACTIVE'", words[0].downcase, words[1].downcase)
        for patient in results
          if patient.organization == @organization
            patients.append(patient)
          end
        end
      end
      # iterate results, and do your shizzle nizzle
      json = []
      for patient in patients
        node = {
          :profile => {
            :first_name => patient.first_name,
            :last_name => patient.last_name,
            :fullname => patient.fullname,
            :photo_uuid => patient.photo_uid,
            :lifesquare_id => patient.lifesquare_uid_str,
            :uuid => patient.uuid,
            :confirmed => patient.confirmed,
            :current_coverage => patient.current_coverage
          },
          :account => {
            :email => patient.account.email,
            :phone => patient.account.mobile_phone,
            :uuid => patient.account.uid,
            :provider => patient.account.provider?,
            :organization => @organization.uuid,
            :sign_in_count => patient.account.sign_in_count,
            :current_sign_in_at => patient.account.current_sign_in_at,
            :last_sign_in_at => patient.account.last_sign_in_at,
            :confirmed => patient.account.confirmed_at,
            :signup_platform => patient.account.signup_platform
          }
        }
        json.append(node)
      end
      render json: {
        :results => json
      }
    end

  end
end