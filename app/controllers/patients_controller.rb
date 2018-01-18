class PatientsController < ApplicationController
  before_action :authenticate_account!
  before_action :obtain_patient, :except => [:index, :new, :show_webview_network]

  WillPaginate.per_page = 10

  # GET /profiles
  # GET /profiles.json
  def index
    @deleted_patients = current_account.deleted_patients
    @patients = current_account.active_patients
    @all_patients = {
      :active => @patients,
      :deleted => @deleted_patients
    }
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @all_patients }
    end
  end

  def confirm
    @onboarding_details = calculate_onboarding_progress(@patient, 'confirm')
  end

  # GET /profiles/uuid/
  # and confirm
  def show
    # we should actually handle it legit style via a filter, but this works
    @patient_details = @patient.get_details('*')
    @privacy_options = Values.call('privacy')
    @import_emrs = Rails.configuration.import_emrs
    @onboarding_details = calculate_onboarding_progress(@patient) # we're not on a step… but meh, we have completed something or other, meh awks

    @display_confirm = false
    if params[:confirm]
      @display_confirm = true
    end

    if @patient.has_expired_coverage
      flash[:notice] = 'Please <a href="/lifesquares/renew">renew your coverage</a>!'
    end
  end

  # time to bunk the configuration / convention seesaw
  # GET /profiles/uuid/edit-personal, /profiles/uuid/edit-medical, /profiles/uuid/edit-contacts
  def edit_personal
    edit_profile_section(params[:uuid], 'personal')
  end

  def edit_medical
    edit_profile_section(params[:uuid], 'medical')
  end

  def edit_contacts
    edit_profile_section(params[:uuid], 'contacts')
  end

  def edit_profile_section(uuid, section)
    # which one?
    @patient_details = @patient.get_details(section)
    # TODO: put in a view helper or something
    @privacy_options = Values.call('privacy')
    @countries = Values.call('country')
    @us_states = Values.call('state')
    @directive_types = Values.call('directive')
    @document_types = Values.call('document')
    # meh
    @import_emrs = Rails.configuration.import_emrs
    @onboarding_details = calculate_onboarding_progress(@patient, section)

    if section == 'personal'
      @genders = Values.call('patient', 'gender')
      @ethnicities = Values.call('patient', 'ethnicity')
      @eye_colors = Values.call('patient', 'eye_color')
      @hair_colors = Values.call('patient', 'hair_color')
      @blood_types = Values.call('patient', 'blood_type')
      @languageCodes = Values.call('language_code')
      @languageProficiency = Values.call('patient_language', 'proficiency')
      @residenceTypes = Values.call('patient_residence', 'residence_type')
      @lifesquareLocationTypes = Values.call('patient_residence', 'lifesquare_location_type')
    end

    if section == 'medical'
      @reactions = Values.call('patient_allergy', 'reaction')
      @frequencies = Values.call('patient_therapy', 'therapy_frequency')
      @quantities = Values.call('patient_therapy', 'therapy_quantity')
    end

    if section == 'contacts'
      @care_provider_classes = Values.call('patient_care_provider', 'care_provider_class')
      @contact_relationships = Values.call('patient_contact', 'relationship')
    end
    @patient_id = @patient.patient_id # con legacy
    if @patient.has_expired_coverage
      # TODO: safe & proper way of using view helpers without breaking all the tings
      flash[:notice] = 'Please <a href="/lifesquares/renew">renew your coverage</a>!'
    end

    respond_to do |format|
      format.html {
        render template: "patients/edit_#{section}"
      }
      # format.json { render :json => {:patient => @patient, :details => @patient_details} }
    end   
  end

  # GET /profiles/:uuid/edit-emergency-contacts
  def edit_emergency_contacts
    @emergency = PatientContact.nonself_by_patient_id(@patient.patient_id)
    @onboarding_details = calculate_onboarding_progress(@patient, 'emergency') # or is it emergency, blablablabla
    @contact_relationships = Values.call('patient_contact', 'relationship')
    @privacy_options = Values.call('privacy')
    # TODO: protect this house
    # redirect_to( @patient.confirmed? ? patient_summary_path : patient_confirm_path ) and return if @emergency.empty?
  end

  # GET for now, because we're just submitting the form, or something lol, cheesy and hackable and all that stuff
  # Because because
  def finish_confirmation
    # validate against some things here
    # like the patient state, and manual data skips if necessary
    if !@patient.confirmed
      @patient.confirmed = true
      @patient.save

      if params[:create] != nil and params[:create]
        redirect_to patient_new_path
        return
      else
        # for awesome town, we should run through our continue method, aka workflow manager
        redirect_to patient_continue_setup_path(@patient.uuid)
        return
      end
    end
    # last ditch effort here
    if params[:create] != nil and params[:create]
      redirect_to patient_new_path
      return
    end

    # toss back otherwise, but this could be the wrong message, but it's ok
    flash[:notice] = 'Please resume setup'
    # get your double redirects on, hopefully this works?
    redirect_to patient_continue_setup_path(@patient.uuid)
  end

  def setup_complete
    @onboarding_details = calculate_onboarding_progress(@patient)
  end

  # GET /profiles/:uuid/webview/:privacy
  def show_webview
    @privacy_options = Values.call('privacy')
    @default_privacy_message = Rails.configuration.privacy_permission_denied_message
    @view_permission = params[:privacy]
    @permission = @privacy_options[0]
    @privacy_options.each_with_index do |opt, index|
      if opt[:value] == @view_permission
        @permission = @privacy_options[index]
        break
      end
    end

    @owner = true
    @patient_details = @patient.get_details('*')
    @context = 'web'
  end

  # GET /profiles/:uuid/network
  def show_network
  end

  def show_network_inbound
    # TODO: this is mad confusing, damn you chris!
    @objects = @patient.network_granters.paginate(:page => params[:page])
    @pending = @patient.network_granters_pending
    @privacy_options = Values.call('privacy')
    # TODO: state son
    render template: "patient_network/shared_with_you"
  end

  def show_network_outbound
    # TODO: this is mad confusing, damn you chris!
    @objects = @patient.network_auditors.paginate(:page => params[:page])
    @pending = @patient.network_auditors_pending
    @privacy_options = Values.call('privacy')
    # TODO: state son
    render template: "patient_network/you_have_shared"
  end

  # GET /profile/:granter_patient_uuid/:auditor_patient_uuid/webview
  def show_webview_network
    
    # is our auditor patient id having our own account
    @auditor_patient = Patient.where(:uuid => params[:auditor_patient_uuid], :status => 'ACTIVE').first
    @granter_patient = Patient.where(:uuid => params[:granter_patient_uuid], :status => 'ACTIVE').first

    if @auditor_patient == nil or @granter_patient == nil
      # log this
      render :text=>'No Network Connection Found', :status=>404
      return
    end

    if current_account.account_id != @auditor_patient.account_id
      render :text=>'Permission Denied', :status=>403
      return
    end

    @view_permission = 'public'

    # accepted at is not nil, bake it into the request, so many ways to do it
    patnet = PatientNetwork.where(:granter_patient_id => @granter_patient.patient_id, :auditor_patient_id => @auditor_patient.patient_id).first
    if patnet == nil or patnet.joined_at == nil
      # TODO: DO BETTER, render inside default layout, yikes
      render :text=>'No Network Connection Found', :status=>404
      return
    end

    # TODO: bundle into some container
    @view_permission = patnet.privacy
    @owner = false
    
    @patient = @granter_patient
    # the mega set of data here
    @patient_details = @patient.get_details('*')

    # TODO: put in a view helper or something
    @privacy_options = Values.call('privacy')
    @default_privacy_message = Rails.configuration.privacy_permission_denied_message

    @context = 'web'

    # @ram question   
    if @auditor_patient.account.provider? # || patnet.privacy == 'provider'
      # TODO: update to a keyword based signature, vs positional arguments
      # TODO: RATELIMIT THE CRAP OUT OF THIS, otherwise each refresh or whatever will SPAM the entire network
      # PostscanNotification.call(@auditor_patient.account, @granter_patient, patnet)
    end

    # audit trail here

    audit = Audit.new
    audit.scanner_account_id = @auditor_patient.account.account_id
    if @granter_patient.lifesquare
      audit.lifesquare = @granter_patient.lifesquare.lifesquare_uid
    end
    # # audit.content = rendered.to_s
    audit.is_provider = @auditor_patient.account.provider?
    audit.is_owner = false
    audit.privacy = @view_permission
    audit.platform = 'web'
    # populate geo
    # audit.latitude = 
    # audit.longitude = 
    # populate io
    audit.ip = request.remote_ip
    audit.save

  end

  # ------------------------------------- workflow

  # GET /profiles/new
  # GET /profiles/new.json
  def new
    @patient = Patient.create()
    # does not work based on ActiveModel::MassAssignmentSecurity::Error
    # @patient = Patient.create(params.merge({:create_user => current_account.account_id, :update_user => current_account.account_id}))
    @patient.create_user = current_account.account_id
    @patient.update_user = current_account.account_id
    
    # PatientController:personal checks for these and sets to null
    @patient.birthdate = DateTime.new(1,1,1)
    @patient.account_id = current_account.account_id
    
    # TODO: investigate PK issue, could be backend specific
    if @patient.save
      account_session['patient_id'] = @patient.patient_id
  
      respond_to do |format|
        format.html { redirect_to patient_edit_personal_path(@patient.uuid) }
        format.json { render :json => @patient }
      end
    else
      redirect_to patients_path, :notice => "There was an error creating a new record"
    end
  end

  # GET /profiles/:uuid/continue-setup
  def continue_setup
    begin
      state = obtain_onboarding_progress(@patient) #aka the next action - one past what is completed
      case state
      when ONBOARDING_COMPLETE
        flash[:notice] = 'All required tasks are complete'
        redirect_to patient_show_path(@patient.uuid)
        return
      when 'lifesquare'
        redirect_to lifesquares_show_renew_path
        return
      when 'confirm'
        redirect_to lifesquares_show_assign_path
        return
      when 'emergency'
        redirect_to patient_confirm_path(@patient.uuid)
        return
      when 'contacts'
        redirect_to patient_edit_emergency_contacts_path(@patient.uuid)
        return
      when 'medical'
        redirect_to patient_edit_contacts_path(@patient.uuid)
        return
      when 'personal'
        redirect_to patient_edit_medical_path(@patient.uuid)
        return
      when 'account'
        redirect_to patient_edit_personal_path(@patient.uuid)
        return
      end
    rescue
      redirect_to patient_edit_personal_path(@patient.uuid)
    end
  end
end
