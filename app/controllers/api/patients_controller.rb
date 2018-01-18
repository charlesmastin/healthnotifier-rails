module Api
  class PatientsController < Api::ApplicationController
    before_action :authenticate_account, except: [:profile_photo] #:unless => :request.get?
    before_action :establish_patient, except: [:index, :create, :create_basic]

    def index
      
      # ok use a legit where clause on Patient to filter out all the noise
      all_your_patients = Patient.where(:account_id => @account.account_id, :status => 'ACTIVE').order('create_date')

      # make this error tolerant, because you know our data can get a bit fractured
      patients = []

      all_your_patients.each do |p|
        
        patient = {
          :FirstName => p.first_name,
          :LastName => p.last_name,
          :MiddleName => p.middle_name,
          :Name => p.name_extended,
          :Gender => nil,
          :Age => p.age_str,
          :ProfilePhoto => patient_photo(p, request),
          :PatientId => p.uuid,
          :WebviewUrl => nil,
          :LifesquareId => nil,
          :Confirmed => p.confirmed,
          :CreateDate => p.create_date,
          :LastUpdate => p.last_update,
          # available stickers, etc
          # status on transactional stuffs
        }

        if p.gender
          patient[:Gender] = p.gender.titlecase
        end

        coverage = p.current_coverage
        if coverage
          patient[:Coverage] = {
            :EndDate => coverage.coverage_end,
            :Recurring => coverage.recurring,
            :StickerCredits => coverage.sticker_credits
          }
        else
          patient[:Coverage] = nil
        end

        if p.lifesquare_uid_str != ""
          patient[:LifesquareId] = p.lifesquare_uid_str
          patient[:WebviewUrl] = "%s%s%s" % [request.protocol, request.host_with_port, api_lifesquare_webview_path(p.lifesquare_uid_str)]
        end

        # some additinoal stuffs
        patients.push(patient)

      end

      render json: { :Patients => patients }

      # return a list of patients for the authed account, pretty basic, then provide sufficient top level info

      # when we iterate, check on some of the properties like, current coverage, and complete registration

      # we can use these attributes to show grouped tables or whatever in the clients
    end

    def show
      # retrieve a full json data set for an individual patient, this is the modern webview replacement
      # we need to sort out how to abstract our data formatters for various types and
      # also send more raw json so clients can decide if necessary
      # the initial goal is to reduce the need for much native view programming for formatting n such
      # TODO: permissions filtering - on server (since we don't want to transmit extra and have client guess)
      # but yea, meh, defer that now
      # temporary ownership check

      # if @patient.account_id != @account.account_id
      #   render json: {
      #     :success => false,
      #     :message => "Permission Denied"
      #   }, status: 403
      #   return
      # end
      # query the actual permission level, lol son

      view_permission = @patient.view_permission_for_account(@account)

      patient_details = @patient.get_details('*') # it's not enough to pass back a boolean, for permission denined, because that could be a thing, in the db for that column
      # decorate with permissions lookup on the collections attributes, let's assume it's safe to execute on the entire set of attributes initially
      # all of these keys are gonna be arrays
      # let's clone our active record instances into basic hash maps ok
      # really this needs to move to a serializer
      # this is a quick hack
      patient_details.keys.each do |key|
        # make a new clean one
        cleaned = []
        # permission scrub each item
        patient_details[key].each do |obj|
          if Patient::obj_has_view_permission(obj, view_permission) || key == 'languages'
            cleaned.append(obj)
          else
            cleaned.append({:error => 'privacy_restricted'})
          end
        end

        patient_details[key] = cleaned
        # swap out the old one
      end

      # patient_details['profile'] = @patient

      # step 2, go through a controlled burn on specific attributes here, of course, we could also set itup, to just iterate all the children probably easier 
      # custom serializer for patient so we can nest objects, son

      # essentially this ghetto times son, a little tediuous carpel tunnel never hurt anyone
      progress_state = obtain_onboarding_progress(@patient)
      progress_index = obtain_onboarding_state_index(progress_state)

      cleaned = {
        # :patient_id => @patient.patient_id,
        :uuid => @patient.uuid,
        :lifesquare_id => @patient.lifesquare_uid_str != "" ? @patient.lifesquare_uid_str : nil,
        :photo_uuid => @patient.photo_uid,
        :photo_url => patient_photo(@patient, request), # sans dimensions, son
        :birthdate => @patient.birthdate,
        :age => @patient.age(@patient.birthdate, true),
        # WTF - not privacy managed??? WTF SON
        :gender => Patient.genders[@patient.gender], # TODO: so… yea, we need to handle the nil vs empty string, because we'll get nil if it was ""

        # maybe a bit excessive :)
        :first_name => @patient.first_name,
        :last_name => @patient.last_name,
        :middle_name => @patient.middle_name,
        :name_suffix => @patient.name_suffix,
        :suffix => @patient.name_suffix, # OOOPSIES
        :name => @patient.name_extended,
        :fullname => @patient.fullname,

        :organ_donor => @patient.organ_donor?,

        # WTF - not privacy managed??? WTF SON
        :maternity_state => @patient.maternity_state,
        :maternity_due_date => @patient.maternity_due_date_mask,

        # f your permissions anyhow
        :blood_type => Patient.blood_types[@patient.blood_type],

        #
        :searchable => @patient.searchable,
        
        :biometrics_privacy => @patient.biometrics_privacy,
        :demographics_privacy => @patient.demographics_privacy,

        :confirmed => @patient.confirmed
        
      }

      # IF owner, pass on LS#???meh meh meh

      # check biometrics
      if Patient::obj_has_view_permission(@patient, view_permission, 'biometrics_privacy')

        # ok, no worries, son
        #cleaned[:biometrics] = {
        cleaned = cleaned.merge({
          :biometrics_restricted => false,
          :blood_type => Patient.blood_types[@patient.blood_type],
          :height => (@patient.height != nil) ? @patient.height : nil, # yea son
          :weight => (@patient.weight != nil) ? @patient.weight : nil,
          # END THE STRAIGHT WRONG SECTION, back to usually wrong
          :pulse => @patient.pulse,
          :bp_systolic => @patient.bp_systolic,
          :bp_diastolic => @patient.bp_diastolic,
          :hair_color => Patient.hair_colors[@patient.hair_color],
          :eye_color_both => @patient.eye_color_both, # not 100% sure, why there is a magic accessor here
        })
      else
        # NEED TO KNOW BASIS SON
        # cleaned[:biometrics_privacy] = 'restricted' # TODO THIS IS SHORT TERM, because as an author this is horrible
        # cleaned[:biometrics] = {
        #   :privacy => 'restricted'
        # }
        # MEH MEH MEH
        cleaned = cleaned.merge({
          :biometrics_restricted => true
        })
      end

      if Patient::obj_has_view_permission(@patient, view_permission, 'demographics_privacy')
        # cleaned[:demographics] = {
        #   :ethnicity => @patient.ethnicity,
        #   :gender => @patient.gender,
        # }
        cleaned = cleaned.merge({
          :demographics_restricted => false,
          :ethnicity => Patient.ethnicities[@patient.ethnicity],
          :gender => Patient.genders[@patient.gender]
        })
      else
        # except not really
        cleaned = cleaned.merge({
          :demographics_restricted => true
        })
        # cleaned[:demographics] = {
        #   :privacy => 'restricted'
        # }
      end

      patient_details['profile'] = cleaned

      available_careplans = 0

      coverage = @patient.current_coverage
      if coverage
        coverage_node = {
          :start_date => coverage.coverage_start,
          :end_date => coverage.coverage_end,
          :recurring => coverage.recurring,
          :sticker_credits => coverage.sticker_credits
        }
        available_careplans = CarePlanProcessor::get_patient_care_plans(@patient.patient_id).count
      else
        coverage_node = nil
      end

      # campaign, specific trimmed down bits here, only "public" read attributes
      campaign_node = nil
      organization_node = nil

      # make the attributes in the models, so we can reuse in other contexts
      if @patient.lifesquare != nil
        # additional org lookup too?
        if @patient.lifesquare.campaign != nil
          campaign = @patient.lifesquare.campaign
          # TODO, sketchy, replace with a campaign.to_json model method bro
          campaign_node = campaign.to_json_public
          if campaign.organization != nil
            organization_node = campaign.organization.to_json_public
          end
        end
      end

      # MISC config stuff
      patient_details['meta'] = {
        :coverage_cost => @patient.coverage_cost,
        :coverage => coverage_node,
        :replacement_cost => Rails.configuration.default_replacement_sticker_cost, # TODO: USE THE to-be-created patient model method son
        :onboarding_state => progress_state,
        :onboarding_index => progress_index,
        :available_cards => @patient.account.get_available_cards(),
        :owner => @patient.account_id == @account.account_id ? true : false,
        :available_careplans => available_careplans,
        :campaign => campaign_node,
        :organization => organization_node
      }

      # if we be the owner son
      if @patient.account_id == @account.account_id
        # query the social network
        # query the access log
        patient_details['network'] = {
          :granters => @patient.network_granters.all,
          :granters_pending => @patient.network_granters_pending.all,
          :auditors => @patient.network_auditors.all,
          :auditors_pending => @patient.network_auditors_pending.all,
        }
        patient_details['access_log'] = @patient.get_recent_audit
      end

      
      

      

      # DO THE SCRUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUB DUBDUBDUBDUBDUBDUBDUBDUBDUBDUBDUBDUBD

      render json: patient_details, status: 200
    end

    def delete
      # TODO: check session based auth sucka sucka nuts butter sauce, jim butterfield edition battlefield 1 betas
      # if we had recurring coverage cancel that too
      cancelled = false
      cancelled_coverages = []
      if @patient.current_coverage && @patient.current_coverage.recurring
        cancelled = @patient.cancel_coverage
        if cancelled
          cancelled_coverages.push(@patient)
        end
      end

      # at some level, we should probably return something other than 200, if we were all in to the spec and such so on and so forth
      @patient.deleted!

      if @patient.save
        begin
          flash[:notice] = 'Profile Deleted'
        rescue
        end
        # TODO: send an email notification, son

        # send the email son
        email = @account.email
        if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
          subject = "Lifesquare Profile Deleted"
          begin
            AccountMailer.send_email(email, subject, 'patients/mailer/delete', {
              :account => @account,
              :patient => @patient,
              :cancelled_coverages => cancelled_coverages
              }).deliver_later(wait: 1.minute)
          rescue
            # woot not much to see
          end
        end

        # at any rate, the next iteraction of the patients screen will show that patient in the DELETED SECTION SUCKA NUTS
        render :json => {:success=>true, :message=>"Profile DAAAAAALETED"}
        return
      end

      render json: {
        :success => false,
        :message => "Error deleting"
      }, status: 500
      return
    end

    # POST /profiles
    # POST /profiles.json
    def create
      # this is only to create new stubs of patients
      # TODO: phase this out
      @patient = Patient.new()

      # if the birthdate doesn't exist, toss it up in 'der
      unless params[:birthdate] != nil
        @patient.birthdate = DateTime.new(1,1,1)
      end

      @patient.create_user = @account.account_id
      @patient.update_user = @account.account_id
      @patient.account_id = @account.account_id

      if @patient.save
        # TODO: responders gem son http://www.justinweiss.com/articles/respond-to-without-all-the-pain/
        # TODO: convert to modern json attribute naming conventions
        render json: {
          :uuid => @patient.uuid
        }, status: 200
      else
        render json: @patient.errors, :status => :unprocessable_entity
      end
    end

    # TODO: temp endpoint before folding into something unified
    def create_basic

      #byebug

      # TODO: only set wel formed attributes son

      # patient
      patient = Patient.new()
      patient.account_id = @account.account_id
      patient.create_user = @account.account_id
      patient.update_user = @account.account_id

      # profile basics
      patient.first_name = params[:first_name]
      if params[:middle_name] != nil && params[:middle_name] != ""
        patient.middle_name = params[:middle_name] # nil check though
      end
      patient.last_name = params[:last_name]
      patient.birthdate = params[:birthdate] # meh meh meh de-serialize?
      if params[:gender] != nil
        patient.gender = params[:gender]
      end
      patient.demographics_privacy = "provider"
      # biometrics
      # default privacy son
      # needs to be in inches? dafu
      if params[:height].to_i > 0
        patient.height = params[:height].to_i # conversion city though
      end
      # needs to be in KG
      if params[:weight].to_i > 0
        patient.weight = params[:weight].to_i # conversion city though
      end
      if params[:eye_color] != nil
        patient.eye_color_both = params[:eye_color] # conversion city though
      end
      if params[:hair_color] != nil
        patient.hair_color = params[:hair_color] # conversion city though
      end
      patient.biometrics_privacy = "public"


      if patient.save
        # nest dem json brobra
        # not permitted, but whatever, we're doing direct access now! FTW
        if params[:residence]
          # TODO: use the ORM style blabla patient.residences.blbla WTF
          residence = PatientResidence.new()
          residence.address_line1 = params[:residence][:address_line1]
          ##### LINE 2 doe?
          if params[:residence][:address_line2]
            residence.address_line2 = params[:residence][:address_line2]
          end
          residence.city = params[:residence][:city]
          residence.state_province = params[:residence][:state_province]
          residence.postal_code = params[:residence][:postal_code]
          residence.country = params[:residence][:country]
          residence.residence_type = "HOME"
          residence.mailing_address = true # guessing here
          residence.privacy = "private"
          # lifesquare location type OMG
          residence.lifesquare_location_type = "Other" # lolzin
          # manually populate the user though OMG
          residence.create_user = @account.account_id
          residence.update_user = @account.account_id
          residence.patient_id = patient.patient_id
          # meh, meh, meh
          # TODO: transaction and rollback though
          residence.save

        end

        render json: {
          :uuid => patient.uuid
        }, status: 200
        return

      end
      
      # TODO: proper error handling
      render json: {

      }, status: 500


    end

    # TODO: create distinct endpoints for "restoring" a patient son
    # that way we can guard all operations with :status => 'ACTIVE'
    # except we would use the enum active? if we/I could figure out how to do it

    # PUT /profiles/1
    # PUT /profiles/1.json
    def update
      whitelisted = params.permit(Patient.get_permitted_params)
      @patient.update whitelisted
      @patient.update_user = @account.account_id if @patient.changed?

      respond_to do |format|
        if @patient.save
          #format.html { redirect_to @patient, :notice => 'Patient was successfully updated.' }
          format.json { render :json => @patient.to_json, :status => 200 }
        else
          #format.html { render :edit }
          format.json { render :json => @patient.errors, :status => :unprocessable_entity }
        end
      end
    end

    def confirm
      @patient.confirmed = true
      if @patient.save
        render json: {
          :success => true,
          :message => "Patient Confirmed",
        }, status: 200
      else
        render json: {
          :success => false,
          :message => "Patient Confirmation Failed",
        }, status: 500
      end
    end

    def coverage_cancel_recurring
      if @patient.account_id != @account.account_id
        render json: {
          :success => false,
          :message => "Permission Denied"
        }, status: 403
      end
      coverage = @patient.current_coverage
      if coverage != nil
        cancelled = @patient.cancel_coverage
        if cancelled
          email = @patient.account.email
          if !(validation_errors = ValidatesEmailFormatOf::validate_email_format(email))
            AccountMailer.send_email(email,
              "Lifesquare subscription cancelled",
              'patients/mailer/subscription_cancel',
              {
                :coverage => coverage,
              }).deliver_later(wait: 1.minute)
          end

          render json: {
            :success => true,
            :message => "You cancelled the subscription"
          }
        else
          render json: {
            :success => false,
            :message => "Stripe Fail"
          }, status: 500
        end

      else
        render json: {
            :success => false,
            :message => "Missing Coverage"
          }, status: 404
      end
    end

    def profile_photo
      # Single entry point for profile photos, son
      # -------------------------------------------
      # GET: stream it back (TODO: handle prod caching, thumbnail and crop dimensions) optional circle croppers (for email and low-tech)
      # POST: Toss it in - but only if one doesn't exist, or create a new one when we support multiples
      # PUT: Update it (either a new image, or just crop params)
      # DELETE: Trash it

      # FOR POST/PUT

      # {
      #   "Crop": {
      #     "OriginX": 0,
      #     "OriginY": 0,
      #     "Width": 100,
      #     "Height": 100
      #   },
      #   "ProfilePhoto": {
      #     "File": "base64yournuts",
      #     "Name": "originalname.jpg",
      #     "Mimetype": "application/jpeg"
      #   }
      # }

      

      # check for permissions
      unless request.get?
        authenticate_account # TODO: sort this out in the before_action definition
        # TODO: check owner action
        if @patient.account_id != @account.account_id
          render json: {
            :success => false,
            :message => "Permission Denied"
          }, status: 403
          return
        end
      end

      if request.delete?
        # lol, high level question, should tranformative model method do the saving?
        @patient.remove_photo_resources
        if @patient.save
          render json: {
            :success => true,
            :message => "Photo deleted",
          }, status: 200
          return
        else
          # :unprocessable_entity
          render json: {
            :success => false,
            :message => "Error saving"
          }, status: 500
          return
        end
      end

      if request.get?
        data = nil
        if @patient.photo_uid != nil
          # only attempt a pull if we think we have it, although the service shoudl also bail
          data = OrientDocumentDigitized.call(S3Download.call(@patient.photo_uid))
        end
        # FOR now, assume caching happens in the service, and we're requesting the original item
        if data != nil
          # iOS has some display bugs that certain aspect ratios will bleed out of the container, we should square crop here at minimum
          # TODO: handle custom mimetypes son, original filename
          # TODO: stream this bizzle from S3 via nginx, and some fanciness
          # TODO: thumbnail (optional)
          # TODO: cropping (optional)
          # TODO: caching - downstream, if in fact we do all those things
          # raw queries won't crop son
          format = 'JPG'
          if params[:width] != nil and params[:height] != nil
            img = Magick::Image.from_blob(data).first
            # do we have a crop zone, do this more ruby-esque
            if @patient.photo_thumb_crop_params != nil or @patient.photo_thumb_crop_params != ''
              # This works great but the data is not stored in True size™ we must rectify on the client
              # And also, cleanup existing crop data in the db
              # cropduster = @patient.photo_thumb_crop_params.split("x")
              # moredust = cropduster[1].split("+")
              # dimensions = {
              #   :x => moredust[1].to_i,
              #   :y => moredust[2].to_i,
              #   :height => cropduster[0].to_i,
              #   :width => moredust[0].to_i
              # }
              # img.crop!(dimensions[:x], dimensions[:y], dimensions[:width], dimensions[:height], true)
              # img.resize!(params[:width].to_i, params[:height].to_i)
              # use the workaround for now to center gravity
              img.crop_resized!(params[:width].to_i, params[:height].to_i)
            else
              # use the workaround for now
              img.crop_resized!(params[:width].to_i, params[:height].to_i)
            end
            if params[:circle]
              # circle croppers 86 edition
              circle = Magick::Image.new(params[:width].to_i, params[:height].to_i)
              gc = Magick::Draw.new
              gc.fill('black')
              gc.circle(params[:width].to_i/2, params[:height].to_i/2, params[:width].to_i/2, 1)
              gc.draw(circle)
              mask = circle.blur_image(1, 0.5).negate
              mask.matte = false
              img.matte = true
              img.composite!(mask, Magick::CenterGravity, Magick::CopyOpacityCompositeOp)

              # stroke
              # gc = Magick::Draw.new
              # gc.fill('none')
              # gc.stroke('orange')
              # gc.circle(params[:width].to_i/2, params[:height].to_i/2, params[:width].to_i/2, 1)
              # gc.draw(circle)
              # stroked = circle

              # img.composite!(stroked, Magick::CenterGravity, Magick::OverCompositeOp)

              #mask.destroy!
              #img.trim!
              format = 'PNG'
            end
            data = img.to_blob { self.format = format }
          end
          send_data data, :type=> 'image/jpeg', :filename => "avatar.jpg", :disposition => :inline, :stream => true, :buffer_size => 4096
        else
          # toss back nil so the various end clients can use a default image SON - never ever return anything client specific here
          render json: {
            :success => false,
            :message => "Photo not found"
          }, status: 404
        end
        return
      end
      
      if request.post? or request.put?
        # at the moment, we aren't making a distinction from the client
        # if we have a file to upload, spin up the s3 connection
        if params[:ProfilePhoto] != nil
          if @patient.add_profile_photo(params[:ProfilePhoto])

          else
            # upload failed bomb out son
            render json: {
              :success => false,
              :message => "Error saving to S3"
            }, status: 500
            return
          end
          
        end

        if params[:Crop] != nil
          if @patient.add_profile_photo_crop(params[:Crop])
            # we just don't care if it fails because its really not important
          end
        end

        # meh, this is questionable

        if @patient.save
          render json: {
            :success => true,
            :message => "Photo saved",
            :url => api_patient_photo_path(@patient.uuid),
            :photo_uid => Base64.encode64(@patient.photo_uid)
          }, status: 200
          return
        else
          # :unprocessable_entity
          render json: {
            :success => false,
            :message => "Error saving"
          }, status: 500
          return
        end

      end
    end
    
    # GET /:uuid/:collection_name
    def collection_index
      # collection alias interceptions
      # made this just for jerry
      # only called via Android App, but I do need it in iOS
      patient = Patient.where(:uuid => params[:uuid]).first
      if ["conditions", "procedures", "immunizations"].include? params[:collection_name]
        if params[:collection_name] == "conditions"
          collection = PatientHealthEvent.conditions_by_patient_id(patient.patient_id)
        end
        if params[:collection_name] == "procedures"
          collection = PatientHealthEvent.procedures_by_patient_id(patient.patient_id)
        end
        if params[:collection_name] == "immunizations"
          collection = PatientHealthEvent.immunizations_by_patient_id(patient.patient_id)
        end
      elsif ["documents", "directives"].include? params[:collection_name]        
        all_docs = patient.get_details('documents')
        collection = all_docs[params[:collection_name]]
      else
        # where dat auth check on this trickle towns™
        collection = params[:collection_name].singularize.classify.constantize.joins(:patient).where(
          'patient.account_id = ? AND patient.uuid = ?', @account.account_id, params[:uuid])
      end

      respond_to do |format|
        #format.html index.html.erb
        format.json { render :json => collection }
      end
    end


    # POST/PUT :uuid/:collection_name
    def collection_write
      # TODO: rework routes to reject the new "alias" collections which we only need on GET
      collection_name = params[:collection_name]
      id_field_name = collection_name.singularize + '_id'

      # custom error handling
      message = nil
      #Pull out any bad fields sent by JavaScript, oh this is comical, should be in JS preSave
      params.delete :start_date_formatted
      # DAMN SON, that is comical!

      # TODO: owner permissions ONLY

      pc = @patient.send(collection_name)
      cids = @patient.send(id_field_name.pluralize)

      # grab da dnynamic params bra

      template_rec = collection_name.singularize.classify.constantize.new

      in_recs = params[collection_name]
      in_recs.try(:each) do |rec|

        # TODO: spin off into normal param definitions, but for now, this is the single point of entry for these objects
        case collection_name
          when "patient_languages"
            rec = rec.permit(:patient_language_id, :language_code, :language_proficiency, :record_order, :_destroy)
          when "patient_residences"
            rec = rec.permit(:patient_residence_id, :address_line1, :address_line2, :city, :state_province,
              :country, :postal_code, :residence_type, :lifesquare_location_type, :lifesquare_location_other,
              :mailing_address, :privacy, :record_order, :_destroy)
          when "patient_therapies"
            rec = rec.permit(:patient_therapy_id, :imo_code, :therapy, :therapy_strength_form, :therapy_frequency,
              :therapy_quantity, :privacy, :record_order, :_destroy)
          when "patient_allergies"
            rec = rec.permit(:patient_allergy_id, :imo_code, :allergen, :reaction, :privacy, :record_order, :_destroy)
          when "patient_health_events"
            rec = rec.permit(:patient_health_event_id, :health_event_type, :health_event, :start_date,
              :privacy, :record_order, :imo_code, :icd9_code, :icd10_code, :_destroy)
          # DOCUMENTS has it's own API bra
          when "patient_insurances"
            rec = rec.permit(:patient_insurance_id, :organization_name, :phone, :policy_code, :group_code,
              :policyholder_first_name, :policyholder_last_name, :privacy, :record_order, :_destroy)
          when "patient_care_providers"
            rec = rec.permit(:patient_care_provider_id, :medical_facility_name, :care_provider_class,
              :phone1, :address_line1, :address_line2, :city, :state_province, :postal_code, :country,
              :first_name, :last_name, :privacy, :record_order, :_destroy)
          when "patient_medical_facilities"
            rec = rec.permit(:patient_medical_facility_id, :name, :phone, :address_line1, :city,
              :state_province, :postal_code, :country, :privacy, :record_order, :medical_facility_type, :_destroy)
          when "patient_pharmacies"
            rec = rec.permit(:patient_pharmacy_id, :name, :phone, :address_line1, :city,
              :state_province, :postal_code, :country, :privacy, :record_order, :_destroy)
          when "patient_contacts"
            rec = rec.permit(:patient_contact_id, :first_name, :last_name, :contact_relationship,
              :notification_postscan, :home_phone, :email, :power_of_attorney, :next_of_kin, :privacy, :record_order, :_destroy)
        end

        # so why are we even passing it in, just be done with it if we're gonna strip it here???
        rec.delete('patient_id')
        rec.delete('create_user')
        rec.delete('create_date')

        # ok, this is mad ghetto son
        # TODO: super temp hack
        # additional stripping of attributes
        # these are the composed meta fields
        rec.delete('title')
        rec.delete('description')
        # these should have been stripped, or ignored
        rec.delete('update_user')
        rec.delete('last_update')
        # patient_therapy_specific
        rec.delete('alert')

        destroy_rec = rec.delete('_destroy')
        pk = rec.delete(id_field_name)
        obj = nil

        if pk.present?
          # Update/delete existing record
          rec_position = cids.index(pk)
          exist_rec = pc[rec_position] if cids.include? pk
          # at silently ignore, may want to pass back a warning
          next unless exist_rec.present?
          if destroy_rec
            pc.delete(exist_rec)
            cids.delete_at(rec_position)
          else
            # hook our phone number validation for updates when number differs
            if collection_name == 'patient_contacts'
              if exist_rec[:home_phone] != rec[:home_phone]
                number = PhoneValidator.call(rec[:home_phone])
                # understood this is a non scoped number, any valid number
                if number != nil
                  # overwrite the data so we format it to e.164
                  rec[:home_phone] = number.phone_number
                else
                  # abort, mid-stroke, this will trip up the model validator, but it won't be able to say a friendly message
                  message = "Invalid phone number found #{rec[:home_phone]}"
                  rec[:home_phone] = nil
                  # @patient.errors.add(:home_phone, "Valid phone number not found")
                end
              end
            end
            exist_rec.attributes = rec
            exist_rec.update_user = @account.account_id if exist_rec.changed? && exist_rec.respond_to?('update_user')
            obj = exist_rec
          end
        elsif !destroy_rec
          # new record

          # hook our phone number validation
          if collection_name == 'patient_contacts'
            number = PhoneValidator.call(rec[:home_phone])
            # understood this is a non scoped number, any valid number
            if number != nil
              # overwrite the data so we format it to e.164
              rec[:home_phone] = number.phone_number
            else
              # abort, mid-stroke, this will trip up the model validator, but it won't be able to say a friendly message
              message = "Invalid phone number found #{rec[:home_phone]}"
              rec[:home_phone] = nil
              # @patient.errors.add(:home_phone, "Valid phone number not found")
            end
          end

          pc.build(rec)
          new_insert = pc.last
          new_insert.update_user = @account.account_id if new_insert.respond_to?('update_user')
          new_insert.create_user = @account.account_id if new_insert.respond_to?('create_user')
          obj = new_insert
        end
      end

      if @patient.save
        render :json => @patient.send(collection_name), :location => @patient
      else
        render :json => { :patient_errors => @patient.errors, :message => message }, :status => :unprocessable_entity
      end
    end

    def export
      # TODO: require owner "action"
      if @patient.account_id != @account.account_id
        render json: {
          :success => false,
          :message => "Permission Denied"
        }, status: 403
      end
      data = Ccd.to_ccd_xml(@patient).to_s
      send_data data, :type=> "application/octet-stream", :filename => "Lifesquare-Export-#{@patient.first_name}-#{@patient.last_name}.xml", :disposition => :inline
    end

    def import
      # TODO: require owner "action"
      if @patient.account_id != @account.account_id
        render json: {
          :success => false,
          :message => "Permission Denied"
        }, status: 403
      end
      begin
        Ccda.import_emr_data(@account, @patient, Base64.decode64(params[:CCD][:File]))
      rescue
        render :json => {:success=>false, :message=>"FAILZONE"}, status: 500
        return
      end
      render :json => {:success=>true, :message=>"Profile Imported"}
    end

    # slightly misleading but more aspirational
    # really just notify that you are a contact
    # but that could be confused with the act of post scan notification somehow
    def confirm_emergency_contacts
      # TODO: we need a more robust way of tracking information change so we avoid re-"confirming" things
      # but also, if info is updated, send that notification yea son!
      anyone_notified = false
      @contacts = PatientContact.nonself_by_patient_id(@patient.patient_id)
      @contacts.each do |contact|
        if contact.list_advise_send_date.blank?
          notified_via_email = false
          notified_via_sms = false
          if contact.email.present?
            begin
              # TODO: template needs to include some way of confirming this there email… yea son
              subject = "#{@patient.name} has listed you as an emergency contact on Lifesquare"
              AccountMailer.send_email(contact.email, subject, 'patients/mailer/emergency_contact', { :patient => @patient } ).deliver_later
              notified_via_email = true
              anyone_notified = true
            rescue

            end
          end
          if contact.home_phone.present?
            phonenum = contact.home_phone.gsub(/\D/, '')
            scrubbed_number = "+1#{phonenum}"
            number = PhoneValidator.call(phonenum)
            if number != nil
              # look at the details, meh meh, probably should roll this bit into the service but whatevs
              if number.carrier['type'] == 'mobile'
                scrubbed_number = number.phone_number
              end
            end

            # TODO: instructions for consuming a confirmation REPLY BITCHES
            sms_body = "#{@patient.name} has listed you as an emergency contact on Lifesquare"
            begin
              client = Twilio::REST::Client.new(
                Rails.configuration.twilio[:account_sid],
                Rails.configuration.twilio[:auth_token]
              )
              message = client.account.messages.create(:body => sms_body,
                :to => scrubbed_number,
                :from => Rails.configuration.twilio[:phone_number])
              notified_via_sms = true
              anyone_notified = true
            rescue Twilio::REST::RequestError => e
              # pass
              # TODO: log somewhere
            end
          end
          if notified_via_email || notified_via_sms
            contact.list_advise_send_date = Time.now
            contact.save
          end
        end
      end

      begin
        if anyone_notified
          flash[:notice] = 'Emergency contacts have been notified'
        else
          # meh, this is an invasive alert in that context FAIL ZONE
          # flash[:notice] = 'No emergency contacts were notified'
        end
      rescue
        # meh
      end

      render json: {
        :success => true,
        :message => "Contacts Done Be Notified, Maybe.",
        :redirect_url => @patient.confirmed? ? patient_show_path(@patient.uuid) : patient_confirm_path(@patient.uuid)
      }, status: 200
    end

    def message_emergency_contacts
      # TODO: # 918 max for SMS
      # > 160 will do chunks of 153

      # WITH LOCATION SON
      # YEA SON, probably not though
      # aka notify
      # send SMS and email to your contacts
      # MVP - text only
      # phase0 - send pics?
      # phase1 - audio attachment
      # phase2 - w/ transcription

      message = params[:message]
      total_notifications_sent = 0

      # TODO: abstract away our service and have a more generic input for this
      # since I feel like it's getting bloated now

      # TODO: sanitize here, for kicks and good measure, bobby drop tables?
      # TODO: do the geocoding
      geo = nil
      if params[:latitude] != nil && params[:longitude] != nil
        results = Geocoder.search("#{params[:latitude]},#{params[:longitude]}")
        # TODO: scrub this down for specificity, for now, just let the template deal with it… LOL YIKES SON
        if results.length > 0
          geo = results[0]
        end
      end

      sms_body = "#{@patient.fullname} sends a message from Lifesquare --- #{message}"
      if geo
        sms_body = "#{sms_body} --- Last known location: #{geo.formatted_address}"
      end
      emergency_contacts = PatientContact.nonself_by_patient_id(@patient.patient_id)
      emergency_contacts.each do |contact|

        context = {
          :contact => contact, # for personalization hooks??
          :patient => @patient,
          :message => message,
          :geo => geo,
          :scantime => Time.now
        }

        if contact.email
          begin
            # TODO: move this elsewhere
            AccountMailer.send_email(contact.email, "#{@patient.fullname} sends a message from Lifesquare!", 'patients/mailer/message_emergency_contact', context).deliver_later
            total_notifications_sent += 1
          rescue
            # woot not much to see
            # TODO: log somewhere
          end
        end

        # this is ghetto, the UI stopped labelling a long time again, so we're not sure it will actually be a mobile phone
        # however the UI copies the data into the mobile phone column
        if contact.home_phone
          phonenum = contact.home_phone.gsub(/\D/, '')
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
            message = @client.account.messages.create(:body => sms_body,
              :to => scrubbed_number,
              :from => Rails.configuration.twilio[:phone_number])
            total_notifications_sent += 1
          rescue Twilio::REST::RequestError => e
            # pass
            # TODO: log somewhere
          end

        end
      end

      # TODO: handle errors
      # if we didn't have any emergency contacts
      # if we were unable to sent to any of them, etc
      if total_notifications_sent == 0
        render json: {
          :success => false,
          :message => "0 Emergency Contacts Notified!"
        }, status: 500 # MEH 412 or something really descriptive perhaps
        return
      end

      # meh, reply with a 200
      render json: {
        :success => true,
        :message => "Emergency Contacts Notified!"
      }, status: 200

    end

    # POST api/v1/patient/emr-lookup
    def emr_patient_search
      
      # if we match an existing provider
      # iterate the available, otherwise toss a 400
      if params[:EmrId] != 'athenahealth'
        render json: {
          :success => false,
          :message => "Bad request: Invalid EMR"
        }, status: 400
        return
      end

      results = nil
      
      if params[:EmrId] == 'athenahealth'
        # TODO: wire in the things
        results = Athenanet.patient_search(
          params[:FirstName],
          params[:LastName],
          params[:DOB],
          params[:Phone],
          params[:SSN])
      end

      # etc for each kind of provider, but with some bs polymorphic adaptor up in the gang of four panties

      if results['totalcount'] == 0
        render json: {
          :success => false,
          :message => "No Patient found"
        }, status: 404
        return
      end

      if results['totalcount'] == 1
        # TODO: return for an interim state, yo, so we can positively confirm,
        # and then transition to the loading state,
        # and then so on and on son
        begin
          Athenanet.import_patient_emr_data(@account, @patient, results['patients'][0]['patientid'])
          render json: {
            :Patient => results['patients'][0]
          }
          return
        rescue
          render json: {
            :success => false,
            :message => 'Import Failed',
            :Patients => results['patients']
          }, status: 500
          return
        end
      end

      # do we have more than 1 result
      # pass it back, ask for disambiguity, or realistically just error out
      if results['totalcount'] > 1
        render json: {
          :success => false,
          :message => 'Conflict: Multiple Patients Found',
          :patients => results['patients']
        }, status: 409
        return
      end
    end

    def popular_terms
      # with respect to the patient, call a bunch of services to filter down the relevant prefilled terminology lists
      # start with the most basic of filtering on age + gender, but eventually existing conditions, etc, so meta
      # MEDICAL RECORD STUFFS is majority dynamic lookup with IMO
      category = params[:category]
      data = nil
      case category
      when 'immunization'
        data = PatientHealthEvent.const_get('IMMUNIZATION_POPULAR_ITEMS')
      when 'condition'
        data = PatientHealthEvent.const_get('CONDITION_POPULAR_ITEMS')
      when 'device'
        data = PatientHealthEvent.const_get('DEVICE_POPULAR_ITEMS')
      when 'allergy'
        data = PatientAllergy.const_get('POPULAR_ITEMS')
      when 'therapy'
        data = PatientTherapy.const_get('POPULAR_ITEMS')
      when 'medication'
        data = PatientTherapy.const_get('POPULAR_ITEMS')
      else
        # nothing here
      end

      if data != nil
        render json: { :results => data }
      else
        render json: {
          :success => false,
          :message => "No terms found"
        }, status: 404
      end

    end

  end
end
