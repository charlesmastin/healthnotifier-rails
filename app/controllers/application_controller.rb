class ApplicationController < ActionController::Base
  FORCE_TOU_ACCEPT_PERIOD = 30*3600*24
  @@assume_tou = false

  protect_from_forgery
  before_action :require_current_tou

  ONBOARDING_COMPLETE = 'ONBOARDING_COMPLETE'

  def home
    if current_account
      redirect_to(patient_index_path)
    else
      redirect_to(login_path)
    end
  end

  def goodbye
    if current_account
      #redirect_to(patient_index_path)
      #return
    end
    render template: "accounts/goodbye"
  end

  def exit_survey_success
    render template: "accounts/exit_survey_success"
  end

private
  
  # TODO: there are 2 of these, this doesn't require ACTIVE, the web UI one does
  def obtain_patient
    @patient = Patient.where(
      :account_id => current_account.account_id,
      :uuid => params[:uuid]
    ).first
    if @patient == nil
      redirect_to patient_index_path
      return 
    end
  end

  def obtain_organization
    @organization = Organization.where(
      :uuid => params[:uuid]
    ).first
    # but ensure the user is a member bro
    # TODO: RTFM on active record though
    # OK, TODO: unique only single role for account to org, lol
    if @organization == nil
      flash[:notice] = 'Invalid Organization'
      redirect_to patient_index_path
      return
    end
    @membership = AccountOrganization.where(
      :account_id => current_account.account_id,
      :organization_id => @organization.organization_id
    ).first
    if @membership == nil
      flash[:notice] = 'You’re not a member of this Organization'
      redirect_to patient_index_path
      return 
    end
  end
  
  def obtain_onboarding_progress(patient)


    # IMPORTANT: This is the measure of progress, not the "next-step"
    # what is the most forward progress that is complete
    # consuming code will then understand how to send to the "next" step in the sequence

    # TODO: move this logic to the model, mmmkay
    # return a string of the last completed step

    # TODO: throw down a patient.model integrity check for accidental data corruption post bla
    # for whatever reason, client this, that or the other could barf something potentially
    # that said, hitting all those checks on every single request seems a little chunky, but that's the cost of doing business I suppose

    if patient.has_current_coverage
      return ONBOARDING_COMPLETE # aka coverage and all that shizzle
    end

    # THIS IS AN OUTSIDE of onboarding state
    # THIS IS WHEN subscription lapses, etc, or is manually cancelled
    if patient.confirmed? and patient.lifesquare_code_str.present? and !patient.has_current_coverage
      return 'lifesquare'
    elsif patient.confirmed?
      return 'confirm'
    end

    # the Patient Lifesquare data is in a subjective "order"
    # in that regard, let's totally make assumptions, and instead do some additive queries here

    # but let's send you back to go for some violations as needed, to avoid further queries, or something like that
    emergency_contacts = PatientContact.where(:patient_id => patient.patient_id)
    if emergency_contacts.count > 0
      notified = []
      emergency_contacts.each do |c|
        if c.list_advise_send_date != nil
          notified.push(c)
        end
      end
      # at least everyone has been notified
      if notified.length == emergency_contacts.count
        return 'emergency' # TODO: update when we actually deal with the verified part, which really has to be out of band
      end
      # return 'emergency'
    else
      # TODO: the new DB param for skipped contacts
      # so it's default to false
      # which means, some users could have slipped through the cracks
      # but that's ok
    end

    # OH LOL ZONE SON,
    # RESEARCH HOW WE CAN CACHE THIS
    # OR PASS THIS DOWN THE CHAIN
    @patient_details = patient.get_details('*')
    # TODO: check the new skipped attribute
    if @patient_details['insurances'].count > 0 || @patient_details['care_providers'].count > 0 || @patient_details['hospitals'].count > 0 || @patient_details['pharmacies'].count > 0
      return 'contacts'
    end

    # do a check on medication_presence
    # basically do we have any data here at all
    # let's table the whole patient details query for the time being
    # new db param for the skipping
    if @patient_details['medications'].count > 0 || @patient_details['allergies'].count > 0 || @patient_details['conditions'].count > 0 || @patient_details['immunizations'].count > 0 || @patient_details['procedures'].count > 0 || @patient_details['documents'].length > 0 || @patient_details['directives'].length > 0 || patient.maternity_state != nil
      return 'medical'
    end

    # HAVE we completed the Personal form, this is a fairly cheap way of determining it
    residences = PatientResidence.where(:patient_id => patient.patient_id)
    if residences.count > 0 && patient.first_name != '' && patient.last_name != '' && patient.birthdate != nil && patient.birthdate.to_s != "01/01/0001 00:00:00"
      return 'personal'
    end
    
    return 'account'
  end

  def obtain_onboarding_state_index(state)
    # we should use an enum instead OH MY, anyhow
    begin
      case state
      ######################################
      when ONBOARDING_COMPLETE
        return 1_000_000_000 #LOL
      ######################################
      #when 'coverage' # this doesn't even exist son
      #  return 8
      ######################################
      ######################################
      ######################################
      when 'lifesquare'
        return 7
      when 'confirm' #### confirm the patient data, blablabla, seems uncessesary
        return 6
      when 'emergency' # separate out contacts - imply some form of confirmation here
        return 5
      when 'contacts' # aka Contacts view, lolzors
        return 4
      when 'medical'
        return 3
      when 'personal'
        return 2
      when 'account'
        return 1
      end
    rescue
      return 1
    end
    return 1
  end

  # this is the momma and the papa
  def calculate_onboarding_progress(patient, current_view_state=nil)

    progress_state = obtain_onboarding_progress(patient) # this is in two calls so we can better use them independently
    progress_index = obtain_onboarding_state_index(progress_state)



    # extend to feed the actual data down the pipe, so we can automate the rendering more, later :)
    # presumably less changes when we update the formula :) meh

    # consider the user, first time 1 patient, or subsequent patients
    # get our total progress
    # byebug
    display_step = obtain_onboarding_state_index(current_view_state) - 1
    total_steps = 6
    percent = ((progress_index.to_f - 1.0) / total_steps.to_f).to_f
    if patient.account.active_patients.count == 1
      display_step = obtain_onboarding_state_index(current_view_state)
      total_steps = 7
      percent = ((progress_index.to_f) / total_steps.to_f).to_f
    end

    # jimmy slaps, make them feel good for accomplishing "nothing"
    if percent == 0.0
      percent = 0.069
    end

    return {
      :progress_state => progress_state,
      :active_index => obtain_onboarding_state_index(current_view_state),
      
      :progress_index => progress_index, # 0 based (absolute)
      :progress_percent => percent * 100, # 0-100


      :display_step => display_step, #offset
      :total_steps => total_steps # (offset)
    }

  end

  # We only give them FORCE_TOU_ACCEPT_PERIOD from the effective date of the TOU to accept with the explicit instructions, after
  # that we may assume an agreement
  def self.assume_tou?
    return @@assume_tou if @@assume_tou
    @@assume_tou = true if Time.now.to_i - Rails.configuration.tou_effective_date > FORCE_TOU_ACCEPT_PERIOD
  end

  def establish_account_patients
    @account = current_account
    @patients = Patient.account_authorized_patients(current_account.account_id)
  end

  def account_patients
    establish_account_patients
    @refer = Account.signup_refers
    @social_panel = account_session['show_social_account_banner'] == true
    account_session['show_social_account_banner'] = false
    @account_name = current_account.email
    true
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(Account) && !current_tou?
      return terms_update_account_path
    else
      # check against a white list of routes? hmm
      # session["account_return_to"] || 
      return patient_index_path
    end
    return patient_index_path
  end

  # redirect to the login page after sign out
  def after_sign_out_path_for(resource)
    new_account_session_path
  end

  def current_tou?
    current_account.terms_of_use.present? && current_account.terms_of_use == Rails.configuration.tou_version
  end

  def require_current_tou
    if account_signed_in? && !account_session[:confirmed_tou_version]
      if current_tou? || self.class.assume_tou?
        account_session[:confirmed_tou_version] = true
      else
        # Force user to accept terms unless they are logging out or deleting their account
        return redirect_to terms_update_account_path unless request.path == destroy_account_session_path ||
          (request.path == account_registration_path && request.request_method_symbol == :delete)
      end
    end
  end

  def require_admin_user
    return authenticate_admin_user!
  end

  def require_lifesquare_employee
    # block if not lifesquare.com, yea son! get it outta here, woooo hoooo shoe
    # Ram, gonna have to use a proper account son!

    unless ((@current_account && @current_account.lifesquare_employee?) || (@account && @account.lifesquare_employee?))
      render :text => '<center style="font-family: monospace;"><span style="font-size:10rem;">😵</span><br />You Can\'t See This Resource!</center>', :status => 403
      return
    end
  end

  def search_for_patients(keywords) # returns array of [patient, address] found
    words = keywords.split(' ')



    # TODO: elasticsearch, but for now, just quick dirty SQL search, yikes
    # oh elastic search would help with all of this...
    # RANSACK UP ON YOUR SELF
    # TODO: add case insensitive lookups everywhere, but we also need to be sure things like email
    # are case insensitive when storing and determining uniques, should be handled by devise

    result_array_of_patient_and_address = []

    # only search names if it's more than one, then do first, last with likes... blablabla
    if words.length > 0
      # are we an email
      # both and now bro balls
        if keywords =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
          account = Account.where("lower(email) = ? AND account_status = 'ACTIVE'", keywords.downcase).first
          if account != nil
            begin
              patients = Patient.where(:account_id => account.account_id, :searchable => true, :confirmed => true)
              patients.each do |p|
                address = PatientResidence.where(:patient_id => p.patient_id, :privacy => ['provider', 'public']).first
                result_array_of_patient_and_address.push([p, address])
              end
            end
          end
        end
      
        if words.length == 2
          patients = Patient.where("searchable = true AND confirmed = true AND lower(first_name) = ? AND lower(last_name) = ?", words[0].downcase, words[1].downcase)
          for patient in patients
            address = PatientResidence.where(:patient_id => patient.patient_id, :privacy => ['provider', 'public']).first
            result_array_of_patient_and_address.push([patient, address])
          end
        end
        if words.length > 2 && words[0].to_i > 0
          # now we assume we have an address, oh well, assumptions, but generally people don't have numbers for names
          # match against address1
          # try to match address line 1, for kicks
          # split up to first ,
          # really just query the patient_id
          addresses = PatientResidence.where("privacy IN ('provider', 'public') AND lower(address_line1) = ?", words.join(' ').downcase)
          for address in addresses
            patient = Patient.where(:searchable => true, :patient_id => address.patient_id, :confirmed => true).first
            if patient != nil
              result_array_of_patient_and_address.push([patient, address])
            end
          end
        end
      
    end
    result_array_of_patient_and_address
  end

  # STATIC METHODS - but should become model methods on PatientNetwork
  def connections_for_account_to_patient(auditor_account_id, granter_patient_id)
    # TODO: more ruby like
    # Rewrite with a JOIN so we can do it in one swoop-de-doop-s
    auditor_patients = Patient.where(:account_id => auditor_account_id, :status => 'ACTIVE')
    connections = []
    for _ap in auditor_patients
      connection = PatientNetwork.where(:granter_patient_id => granter_patient_id, :auditor_patient_id => _ap.patient_id).first
      if connection != nil
        connections.push(connection)
      end
    end
    connections
  end

  # STATIC METHODS - but should become model methods on PatientNetwork
  def view_permission_for_account_to_patient_item(auditor_account_id, granter_patient_id, required_permission)
    # TODO: more ruby like
    connections = connections_for_account_to_patient(auditor_account_id, granter_patient_id)
    permission_granted = false
    if connections.size > 0

      privacy_stack = Values.call('privacy')
      required_permission_index = 0 # default to lowest for whatever reason
      privacy_stack.each_with_index do |p, i|
        if p[:value] == required_permission
          required_permission_index = i
        end
      end
      connections.each do |connection|
        if privacy_stack.map { |p| p[:value] }.index(connection.privacy) >= required_permission_index
          permission_granted = true
          break
        end
      end
    end
    permission_granted
  end

  def find_campaign_with_promo(promo_code)
    return nil if promo_code.to_s.strip.empty?
    # disregard campaign_id, simply check code, is there a match
    campaign = Campaign.where("lower(promo_code) = ?", promo_code.downcase).first
    # TODO: fix this logic
    # active record syntax on query, etc, etc, etc, etc, etc, etc, etc
    now = DateTime.now
    # TODO: this will error out if campaign is not setup correctly
    # suggestion, add more validators to campaign model and enforce in admin
    if campaign && campaign.promo_start_date <= now && campaign.promo_end_date > now && campaign.start_date <= now && campaign.end_date > now
      return campaign
    else
      return nil
    end
  end

end
