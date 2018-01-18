require 'json'
require 'base64'
require 'jwt'

module Api
  class ApplicationController < ::ApplicationController
    # FINE GRAINED VERSIONING - inside the /v1/ namespace
    
    # request.headers["Lifesquare-Client-Version"] = build number - eg 250 (note, needs to further introspect user agent for platform specifics, lul)
    # request.headers["Lifesquare-Client-Version-Name"] = version name - eg 1.4.0
    skip_before_action :verify_authenticity_token # ain't got time for CSRF on this API son
    before_action :authenticate_account, only: [:validate_address, :validate_phone]

    def validate_address
      results = Geocoder.search(params[:address])
      if results.length > 0
        match = false
        results.each do |result|
          # handle string conversion encoding craps
          if result.formatted_address == params[:address]
            # exact match found, so, yea you're good to go
            render json: {
              :results => results,
              :match => true,
              :success => true,
              :message => ""
            }, status: 200
            return
          end
        end
      end
      render json: {
        :results => results,
        :match => false,
        :success => true,
        :message => "Pick an address"
      }, status: 200
    end

    def validate_phone
      # accept only mobile for now
      # that's ok, the items that will accept any phone number will be
      # handled in their endpoints, for now, until we move the logic into the service
      number = PhoneValidator.call(params[:number])
      if number != nil
        # look at the details, meh meh, probably should roll this bit into the service but whatevs
        if number.carrier['type'] == 'mobile'
          render json: {
            :country_code => number.country_code,
            :phone_number => number.phone_number,
            :national_format => number.national_format,
            :success => true,
            :message => "Valid Mobile Phone"
          }, status: 200
          return
        else
          # there is another scenario like literally a non-provisisioned number? but whatever son
          render json: {
            # :details => number, # hopefully this serializes itself? meh
            :success => false,
            :message => "No Valid Mobile Phone"
          }, status: 400
          return
        end
      end
      render json: {
        :success => false,
        :message => "Unknown Error"
      }, status: 500
    end

    def parse_license
      # TODO: error handling my bro
      results = AAMVAParser.call(params[:data])

      if Rails.env == "ddevelopment"
        results[:first_name] = "Jennifer"
        results[:middle_name] = "Elaine"
        results[:last_name] = "Smith"
        results[:birthdate] = "1982-08-26"
        results[:gender] = "F"
        results[:height] = 70
        results[:weight] = 135
        results[:eye_color] = "Brown"
        results[:hair_color] = "Brown"
        results[:address_line1] = "1800 Bryant St."
        results[:address_line2] = "Unit 103"
        results[:city] = "San Francisco"
        results[:state_province] = "CA"
        results[:postal_code] = "94014"
      end

      render json: {
        :results => results,
      }, status: 200
    end
    
    def values
      render json: {
        :model => params[:model],
        :attribute => params[:attribute],
        :values => Values.call(params[:model], params[:attribute]) # use dat service
      }, status: 200
    end

    def static_terms
      # TODO: JW some top level inline css bro
      # exception handling bro
      begin
        page = Nokogiri::HTML(open("https://www.lifesquare.com/terms/"))
        content = '<div style="font-family: sans-serif;">' + page.css('main section div').first.to_html + '</div>'
        render json: {
          :html => content
        }, status: 200
      rescue
        render json: {
          :html => "Please visit https://www.lifesquare.com/terms/ for full terms",
          :redirect => "https://www.lifesquare.com/terms/"
        }, status: 404
      end
    end

    def static_privacy
      # exception handling bro
      # TODO: JW some top level inline css bro
      begin
        page = Nokogiri::HTML(open("https://www.lifesquare.com/privacy/"))
        content = '<div style="font-family: sans-serif;">' + page.css('main section div').first.to_html + '</div>'
        render json: {
          :html => content
        }, status: 200
      rescue
        render json: {
          :html => "Please visit https://www.lifesquare.com/privacy/ for full terms",
          :redirect => "https://www.lifesquare.com/privacy/"
        }, status: 404
      end
    end

    def all_values
      # convenience network performance wrapper for clients that want to persist the lists in memory
      collections = []
      collections.push({:model => 'privacy', :attribute => nil, :values => Values.call('privacy')})
      collections.push({:model => 'document', :attribute => nil, :values => Values.call('document')})
      collections.push({:model => 'directive', :attribute => nil, :values => Values.call('directive')})
      collections.push({:model => 'country', :attribute => nil, :values => Values.call('country')})
      collections.push({:model => 'state', :attribute => nil, :values => Values.call('state')})
      collections.push({:model => 'patient', :attribute => 'gender', :values => Values.call('patient', 'gender')})
      collections.push({:model => 'patient', :attribute => 'ethnicity', :values => Values.call('patient', 'ethnicity')})
      collections.push({:model => 'patient', :attribute => 'hair_color', :values => Values.call('patient', 'hair_color')})
      collections.push({:model => 'patient', :attribute => 'eye_color', :values => Values.call('patient', 'eye_color')})
      collections.push({:model => 'patient', :attribute => 'blood_type', :values => Values.call('patient', 'blood_type')})
      collections.push({:model => 'language_code', :attribute => nil, :values => Values.call('language_code')})
      collections.push({:model => 'patient_language', :attribute => 'proficiency', :values => Values.call('patient_language', 'proficiency')})
      collections.push({:model => 'patient_residence', :attribute => 'residence_type', :values => Values.call('patient_residence', 'residence_type')})
      collections.push({:model => 'patient_residence', :attribute => 'lifesquare_location_type', :values => Values.call('patient_residence', 'lifesquare_location_type')})
      collections.push({:model => 'patient_contact', :attribute => 'relationship', :values => Values.call('patient_contact', 'relationship')})
      collections.push({:model => 'patient_care_provider', :attribute => 'care_provider_class', :values => Values.call('patient_care_provider', 'care_provider_class')})
      collections.push({:model => 'patient_allergy', :attribute => 'reaction', :values => Values.call('patient_allergy', 'reaction')})
      collections.push({:model => 'patient_therapy', :attribute => 'therapy_frequency', :values => Values.call('patient_therapy', 'therapy_frequency')})
      collections.push({:model => 'patient_therapy', :attribute => 'therapy_quantity', :values => Values.call('patient_therapy', 'therapy_quantity')})
      render json: collections, status: 200
    end

  private

    # these are our filters aka helpers, but we really need more fine tuned combinations on each
    def authenticate_account
      # TODO: re-order the check order
      # JWT, legacy tokens, cookies
      # in general are we authenticated
      @account = nil
      # session based portal account check provided by devise
      if current_account
        # assign for convenience in checking further down
        @account = current_account
      else
        # check the mobile auth check, but only if it's a mobile auth request
        # we don't have a super legit way to determine the intent of auth method at this point
        # so it would be incorrect to issue a 400 if we don't have tokens, or whatever

        # check the new bearer auth for OAuth2 password / bearer style auth
        # TODO: better swiss army checking on the auth headers
        if request.headers['Authorization'] && request.headers['Authorization'].include?("Bearer")
          # THIS IS AMATUER HOUR, but it works
          # do the handling of our failed token, or expired token, etc meh meh
          begin
            leeway = 30 # seconds
            token = request.headers['Authorization'].split(" ")[1]
            # decode that like a boss son, so we can be sure it was signed and so on, is this necessary if we persist the token in our db??
            begin
              decoded_token = JWT.decode token, Rails.configuration.lifesquareapi[:hmac_secret], true, { :exp_leeway => leeway, :algorithm => 'HS256' }
              # this was totally not needed though
              # TODO: read the token first, with the library, for expiration, don't even hit the database
              # TODO: blablabla, break apart, and query also with our user though
              account_token = AccountToken.where(:token => token).first
              if account_token != nil
                account = Account.find(account_token.account_id)
                # look at the payload though bro brizzle
                if account.uid == decoded_token[0]["lifesquare_account_uuid"]
                  @account = account
                end
                # TODO: exception handling though
              end

            rescue JWT::ExpiredSignature
              # yea son, do something highly specificic
            end
            
            
          rescue

          end
        end

        # fall back son
        if request.headers['X-Account-Email'] && request.headers['X-Account-Token']
          # THROBACK LOOK UP BRO
          # @account = Account.where("lower(email) = ? AND authentication_token = ? AND account_status = ?",
          #   request.headers['X-Account-Email'].downcase,
          #   request.headers['X-Account-Token'],
          #   'ACTIVE'
          # ).first
          # STRAIGHT temp version
          account = Account.where("lower(email) = ? AND account_status = ?",
            request.headers['X-Account-Email'].downcase,
            'ACTIVE'
          ).first
          if account != nil
            account_token = AccountToken.where("account_id = ? AND token = ? AND account_device_id IS NULL AND DATE(expires_at) > NOW()",
              account.account_id,
              request.headers['X-Account-Token']
            ).first
          end
          # meh zone
          if account != nil and account_token != nil
            @account = account
          end
        end
      end

      # if we wanted extra credit we would return for a bad request
      if @account == nil
        render json: {
          :success => false,
          :message => "Unauthorized: Invalid credentials"
        }, status: 401
        return
      end
    end

    def require_provider
      # block if not provider
      if !@account.provider?
        render json: {
          :success => false,
          :message => "Permission Denied: Must be provider"
        }, status: 403
        return
      end
    end

    def establish_patient
      # this is really a member of patients_controller and patient_network should extend patients to get it
      # this takes the uuid param and cooks it up son
      @patient = Patient.where(:uuid => params[:uuid], :status => 'ACTIVE').first
      if @patient == nil
        render json: {
          :success => false,
          :message => "Patient Not Found"
        }, status: 404
        return
      end
    end

    # ok, this is for the API context, kinda duped, but needed a few differences from the base
    def obtain_organization
      @organization = Organization.where(
        :uuid => params[:uuid]
      ).first
      # but ensure the user is a member bro
      # TODO: RTFM on active record though
      # OK, TODO: unique only single role for account to org, lol
      if @organization == nil
        # BAILZONE
        return
      end
      @membership = AccountOrganization.where(
        :account_id => @account.account_id,
        :organization_id => @organization.organization_id
      ).first
      if @membership == nil
        # TODO: bailzone 3000 response
        return 
      end
    end

    # NOT A FILTER, since it needs lots of dynamic arguments
    def authorize
      # should be flexible, based on a couple conditions
      # self - aka auth account == obj.account for certain things, and all POST, PUT, DELETE, etc
      # for GET, tap the network connections, and check permissions
    end

    # transform formatting filter
    def transform_legacy_request
      # take all BigGuyTimes and make them big_guy_times
      # maintain a manual dict here for special exceptions
    end

    # after filter, given api request version
    def transform_legacy_response
      # take all big_guy_times and make them BigGuyTimes for requests that lack client version headers
      # read up on what is an appropriate way of establishing that
    end

    # this is a helper, it's not a model method because it deals with the request, to qualify a url, although yes we could use _url
    def patient_photo(patient, request)
      # WHY DO WE NEED REQUEST, la la la la la la la la
      photo = "#{request.protocol}#{request.host_with_port}#{ActionController::Base.helpers.asset_path('user-thumbnail-default.png')}"
      if patient.photo_uid
        # stripping this dimensional info is dangerous, but WTF we have like 0 clients connecting
        # bust a cache sauce on dat son son
        photo = "#{request.protocol}#{request.host_with_port}#{api_patient_photo_path(patient.uuid)}?photo_uuid=#{patient.photo_uid}"
        # for legacy clients, append the &width=128&height=128
        if request.headers["Lifesquare-Client-Version"] == nil
          photo = "#{photo}&width=128&height=128"
        end
      end
      photo
    end

    def init_stripe_customer(first_name, last_name)
      # TODO: rewrite this code
      # doesn't accept arguments
      # operates on global scope
      # returns stuff
      if params[:Payment][:Token] != nil
        source = params[:Payment][:Token]
      end
      if params[:Payment][:CardId] != nil and params[:Payment][:CardId].size > 1
        # not exactly sure here
        source = params[:Payment][:CardId]
      end
      # this is a get or nil

      # base metadata object for stripe customer
      # TODO: REMOVE GLOBAL HERE
      @metadata = {
        account_id: @account.uid, # this is what we will integrity check on
        first_name: first_name,
        last_name: last_name
      }

      # THIS CODE IS BALLOCKS
      customer_id = nil
      existing_customer = @account.stripe_customer # it's a circle of logic, but this was a way to remove any direct account touching from inside the CreditCardService
      if existing_customer != nil
        customer_id = existing_customer.id
      end

      result = CreditCardService.create_or_update_customer(
        customer_id,
        @account.email,
        source,
        @metadata,
      )

      if result[:success] and result[:customer] != nil
        @account.stripe_customer_id = result[:customer].id
        @account.save
      end
      # pass it back regardless
      result
    end

  end
end
