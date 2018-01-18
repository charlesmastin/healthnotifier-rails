require 'base64'
require 'rmagick' # OH, it's hanging around in order to set a default crop zone on an image

class Patient < ApplicationRecord

  # BACK FROM THE DEAD SUCKA
  # oh oh oh oh oh, I didn't name it patient_status
  enum status: {
    active: 'ACTIVE',
    deleted: 'DELETED'
  }

  enum ethnicity: {
    asian: 'ASIAN',
    black: 'BLACK',
    hispanic: 'HISPANIC',
    indian: 'INDIAN',
    other: 'OTHER',
    white: 'WHITE'
  }

  def self.formatted_ethnicities
    {
      'ASIAN' => 'Asian',
      'BLACK' => 'Black / African American',
      'HISPANIC' => 'Latino / Hispanic',
      'INDIAN' => 'Indian / South Asian',
      'OTHER' => 'Other',
      'WHITE' => 'White / Caucasian'
    }
  end

  # since this has a tweaked display value, we need a formatter like a gender_formatted or some crap, UG son of a bizzle

  enum gender: {
    female: 'F',
    male: 'M',
    identify_as_female: 'IDENTIFY_AS_F',
    identify_as_male: 'IDENTIFY_AS_M'
  }

  enum hair_color: {
    hair_black: 'Black',
    hair_blond: 'Blond',
    hair_brown: 'Brown',
    hair_gray: 'Gray',
    hair_red: 'Red',
    hair_sandy: 'Sandy',
    hair_white: 'White',
    hair_other: 'Other',
    hair_none: 'None'
    # # DMV ANSI-20 BRO
  }

  # accessor because yup
  def hair_color
    self[:hair_color]
  end

  enum eye_color: {
    eye_black: 'Black',
    eye_blue: 'Blue',
    eye_brown: 'Brown',
    eye_gray: 'Gray',
    eye_green: 'Green',
    eye_hazel: 'Hazel',
    eye_maroon: 'Maroon',
    eye_pink: 'Pink',
    eye_other: 'Other'
    # DMV ANSI-20 BRO
  }

  enum blood_type: {
    a_positive: 'A+',
    a_negative: 'A-',
    b_positive: 'B+',
    b_negative: 'B-',
    ab_positive: 'AB+',
    ab_negative: 'AB-',
    o_positive: 'O+',
    o_negative: 'O-'
  }

  # Associations
  has_many :payments
  has_many :coverages
  belongs_to :account
  has_one :lifesquare

  before_create :set_uuid

  self.sequence_name= :patient_patient_id_seq

  if self.respond_to?(:set_boolean_columns)
    set_boolean_columns :confirmed
  end

  def self.next_patient_id
    if connection.prefetch_primary_key?
      connection.next_sequence_value(Patient.sequence_name)
    else
      # FIXME: seems slightly better than the existing legacy sequence thing
      # FIXME: does not work on MySQL, only sqllite, oh yea AR cursor inconsistencies +1 Django (maybe)
      connection.execute(%q{SELECT MAX(patient_id) + 1 FROM patient})[0][0]
      # connection.execute(%q{SELECT seq+1 FROM SQLITE_SEQUENCE WHERE name='patient'})[0][0]
    end
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def name
    "#{self[:first_name]} #{self[:last_name]}"
  end

  def photo_date_or_infer
    # unclear of use
    self[:photo_date].present? ? self.photo_date.iso8601 : nil
  end

  def has_active_campaign
    #lifesquare.try(:campaign).try(:campaign_status).try(eql?(Campaign::Status::ACTIVE))
    # Explicit search being performed because, as of 11/19/2014, required associations
    # are not estabished
    lifesquare = Lifesquare.where(:patient_id => self.id).first
    if lifesquare.nil?
      return false
    end
    campaign = Campaign.where(:campaign_id => lifesquare.campaign_id).first
    return (campaign and campaign.ACTIVE? and (campaign.end_date) and (DateTime.now < campaign.end_date))
  end

  # Handles the logic for what the payment amount will be for a particular Lifesquare patient.
  # If there is an active coverage, the coverage cost returned will be either the last
  # payment.amount or it will be the last campaign.price_per_Lifesquare_per_year.
  # Even if the account is active, if the user wants to request a new set of stickers, they
  # should come at the cost of the annual subscription.  On the Lifesquare business side,
  # we would ensure no contract would specify an annual contracted fee that is less than our
  # costs for producing and distributing additional stickers.
  def coverage_cost
    most_recent_coverage = get_most_recent_coverage
    # Generic subscription cost in cents of $11/year
    cost = Rails.configuration.default_coverage_cost
    # THIS IS NO NO NO NO NO NO NO NO NO NO NO NO NO NO NO NO DON'T DO IT
    #if(most_recent_coverage and most_recent_coverage.payment)
    #  cost = most_recent_coverage.payment.amount
    #end
    # campaign may be nil
    if has_active_campaign
      cost = lifesquare.campaign.price_per_lifesquare_per_year -
             lifesquare.campaign.user_shared_cost_for_campaign
    end
    return cost
  end


  def get_most_recent_coverage
    # what is this drivel
    most_recent_coverage = Coverage.where(:coverage_status => 'ACTIVE', :patient_id => self.id).first
    if(most_recent_coverage.nil?)
      most_recent_coverage = Coverage.where(:patient_id => self.id).last
    end
    return most_recent_coverage
  end


  # Note that this method currently prorates.  So, if someone is renewing at month #11 of a
  # 1 year subscription, the subsequent fee returned is 11/12 of the usual annual fee
  def prorated_coverage_cost
    non_pro_rated_cost = coverage_cost
    cost =  non_pro_rated_cost
    today = Date.today
    most_recent_coverage = get_most_recent_coverage
    if(most_recent_coverage)
      months_elapsed = month_difference(today, most_recent_coverage.coverage_end)
      if(months_elapsed < 12)
        cost = (cost * (months_elapsed/12))
      end
    end
    return cost
  end


  # Calculates the difference between two dates in months
  def month_difference(a, b)
    difference = 0.0
    if a.year != b.year
      difference += 12 * (b.year - a.year)
    end
    difference + b.month - a.month
  end


  # Price for buying a replacement set of stickers before an annual subscription is ready
  # for renewal. As of now, we are just keeping the cost of an annual subscription and the
  # cost of a "premature" replacement sticker request as the same -- may diverge in the
  # near future
  def sticker_cost
    return coverage_cost
  end


  # Cancel a recurring stripe coverage for a paying customer
  # Does not send a cancel email, should be done from implementation (controller, rake) to send appropriate context message
  def cancel_coverage
    # attempt to kill things, it's really a facet of a stripe customer model, but oh well
    customer = self.account.stripe_customer
    if customer && self.current_coverage && self.current_coverage.recurring && self.current_coverage.stripe_subscription_key
      begin
        cancelled = CreditCardService.cancel_subscription(customer.id, self.current_coverage.stripe_subscription_key)
        self.current_coverage.recurring = false
        self.current_coverage.save
      rescue
        return false
      end
      return true
    end
    return false
  end

  # this is only used to evaluate if a lifesuqare HAS complimentary coverage, misleading name
  # instead, SHOULD HAVE complimentary coverage?
  # only used in one spot, no tests, requires lifesquare to be assigned already which controller code flow does not support

  def provide_complimentary_coverage(lifesquare_uid)
    unless current_coverage
      # applying coverage before having a lifesquare is slightly risky, but it's ok
      # query up the potential lifesquare
      lifesquare = Lifesquare.where(:valid_state => 1, :activation_date => nil, :patient_id => nil, :lifesquare_uid => lifesquare_uid).first
      if lifesquare.nil?
        return false
      end
      if lifesquare.campaign
        cost = lifesquare.campaign.price_per_lifesquare_per_year - lifesquare.campaign.user_shared_cost_for_campaign
        if cost <= 0
          # need a coverage instance if it's free...
          coverage = Coverage.new
          coverage.patient = self
          coverage.coverage_start = Date.today
          coverage.coverage_end   = Date.today + 365
          # coverage.payment = payment
          # free coverage isn't recurring
          coverage.recurring = false
          coverage.coverage_status = 'ACTIVE'
          coverage.save
          current_coverage = coverage
        end
      end
    end
    current_coverage
  end

  def has_expired_coverage
    # only true if has a lifesquare, and no current coverage
    # one-line poignant ruby, bla bla
    if self.lifesquare_uid_str != "" and !self.has_current_coverage
      return true
    end
    false
    # or some strange case of had coverage but doesn't have a lifesquare ??
  end

  def has_current_coverage
    if self.current_coverage != nil
      return true
    end
    false
  end

  def can_request_stickers
    if self.has_current_coverage
      state = CodeSheetPrintRequest.request_already_processed?(self.lifesquare_uid_str)
      if state == false
        return false
      else
        return true
      end
    end
    return false
  end

  def get_recent_audit
    trail = Audit.where(:lifesquare => self.lifesquare_uid_str, :is_owner => false).order('created_at DESC').limit(5)
  end

  def confirmed?
    Patient.char_truth? self[:confirmed]
  end

  # accessor hacks 2016 hacking
  def has_basics?

  end

  def has_demographics?
    # or languages
    if gender.present? or ethnicity.present?
      return true
    end
    return false
  end

  def has_biometrics?
    if blood_type.present? or bp_systolic.present? or pulse.present?
      return true
    end
    return false
  end

  # DELTE THESE OVER EAGER EARLY OPTIMZATIONS
  def maternity_state?
    Patient.char_truth? self[:maternity_state]
  end

  def medication_presence?
    Patient.char_truth? self[:medication_presence]
  end

  def allergy_presence?
    Patient.char_truth? self[:allergy_presence]
  end

  def condition_presence?
    Patient.char_truth? self[:condition_presence]
  end

  def immunization_presence?
    Patient.char_truth? self[:immunization_presence]
  end

  def procedure_presence?
    Patient.char_truth? self[:procedure_presence]
  end

  def directive_presence?
    Patient.char_truth? self[:directive_presence]
  end

  def self.char_truth?(test)
    return false unless test
    # because sqlite stores true as 't'
    return test == true || test.to_s == '1' || test == 't'
  end

  # TODO: standardize these boolean defaults back to the DB
  def organ_donor?
    organ_donor || false
  end

  def age(dob, full_str=false)
    # http://stackoverflow.com/questions/819263/get-persons-age-in-ruby
    age_today = Date.today.year - dob.year
    age_today -= 1 if Date.today < dob + age_today.years
    if not full_str
      return age_today
    end
    if age_today >= 1
      r = (age_today != 1) ? "#{age_today} years old" : "1 year old"
      return r
    else
      now = Time.now.utc.to_date
      months = ((now.year > dob.year) ? 12 : 0) + (now.month - dob.month) - ((now.day < dob.day) ? 1 : 0)
      r = (months != 1) ? "#{months} months old" : "1 month old"
      return r
    end
    # TODO: dialed in humanizer
    # minors - 2 rounded half year fractions
    # less than 2, w/ months
    # less than 3 months weeks only
    # less than 2 weeks days only
    # less than 2 days hours only
  end

  def age_str
    age(birthdate, true)
  end

  def imperialHeight
    if self.height.present?
      totalInches = (self.height * 0.393700787).round
  		feet = String((totalInches / 12).floor)
  		inches = String((totalInches > 12) ? totalInches % 12 : 0)
      # MAY RERGRET THIS
      return "#{feet}' #{inches}\""
  		# return "#{feet}&rsquo; #{inches}&rdquo;".html_safe
		end
		return ''
  end

  def imperialWeight
    if self.weight.present?
      pounds = String((self.weight * 2.20462262).round)
      return "#{pounds} lbs"
    end
    return ''
  end


  def lifesquare_uid_str
    Lifesquare.find_by_patient_id(patient_id).try(:lifesquare_uid).try(:to_s) || ''
  end


  def lifesquare_code_str
    Lifesquare.find_by_patient_id(patient_id).try(:formatted_str) || ''
  end

  # terrible name here, avoiding conflicts and keeping logic central
  def avatar_uid
    if self.photo_uid != nil
      return Base64.urlsafe_encode64(self.photo_uid)
    end
    nil
  end


  def webapp_thumb_url
    thumb = nil
    """
    thumb = self.photo138x138.url if self.photo138x138.present?
    if !thumb.present? && self.photo.present?
      if self[:photo_thumb_crop_params].present?
        geo = self[:photo_thumb_crop_params]
      else
        geo = '138x138#'
      end
      thumb = self.photo.thumb(geo).url
    end
    """
    return thumb || 'user-thumbnail-default.png'

  end


  def photo_s3_storage_path(ext, dim=nil)
    raise "Assigning filename to patient photo but no patient_id present, try preassign_pk" unless patient_id.present?
    p_id = patient_id.to_s
    "patient-photos/#{p_id[-3,3]}/#{p_id[-6,3]}/#{p_id}/#{Time.now.to_i}#{dim ? '-'+dim : ''}.#{ext}"
  end

  def photo_thumb_crop_params=(params)
    return if self[:photo_thumb_crop_params] == params
    self[:photo_thumb_crop_params] = params
    """
    if params.present? && self.photo.present?
      self.photo640x640 = self.photo.thumb(params).thumb('640x640#').data
      self.photo138x138 = self.photo.thumb(params).thumb('138x138#').data
    end
    """
  end

  def remove_photo_resources
    # TODO: remove on S3 SON
    self.photo_uid = nil
    self.photo_thumb_crop_params = nil
    # self.photo = self.photo640x640 = self.photo138x138 = self.photo_thumb_crop_params = nil
  end

  def add_profile_photo(photo, set_default_crop=false)
    # semi-illogical but DRY photo persistence living here, because we need it in both
    # the general patient creation API and the discreet patient profile photo endpoint
    # yes, it just makes sense to keep the latter
    # hmm, oh wells this assumes the standard fileupload API of File, Name, Mimetype
    # calculate all the things we need first
    name = photo[:Name]
    begin
      ext = name[name.rindex('.')+1..name.size-1]
    rescue
      ext = 'jpg'
    end
    key = self.photo_s3_storage_path(ext)
    # wrap this in some failure code, but honestly, if base64 bombs, it all bombs
    data = Base64.decode64(photo[:File])
    if S3Upload.call(key, data, {})
      self.photo_uid = key

      if set_default_crop
        begin
          im = Magick::Image.from_blob(data).first
          self.photo_thumb_crop_params = "#{im.columns}x#{im.rows}+0+0"
        rescue
          # yup, don't care
        end
      end

      return true
    else
      return false
    end
    return false
  end

  def add_profile_photo_crop(crop)
    if crop[:Width].present? && crop[:Width].to_i > 0 && crop[:Height].to_i > 0
      self.photo_thumb_crop_params = "#{crop[:Width].to_i}x#{crop[:Height].to_i}+#{crop[:OriginX].to_i}+#{crop[:OriginY].to_i}"  
      # commentary from OG crew
      # Remove the original once we have the crop params - we won't use the original again,
      # this causes all kinds of problems (the photo is cached on browser, url still works, etc), punt for now
      # @patient.photo = nil
      return true
    end
    return false
  end

  # Table relationships

  has_many :lifesquares, :inverse_of => :patient
  has_many :patient_languages, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_residences, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_health_attributes, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_health_events, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_therapies, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_allergies, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_contacts, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_insurances, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_care_providers, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_medical_facilities, :inverse_of => :patient, :dependent => :destroy
  has_many :patient_pharmacies, :inverse_of => :patient, :dependent => :destroy
  # works all except for userstamp :( has_many :care_providers, :through => :patient_care_providers
  has_many :provider_credentials, inverse_of: :patient, dependent: :destroy

  # has_many :account_patients, :inverse_of => :patient
  # has_many :accounts, :through => :account_patients
  has_many :accounts

  has_many :network_auditors_pending, -> { where "joined_at IS NULL" }, class_name: :PatientNetwork, inverse_of: :granter_patient, foreign_key: :granter_patient_id
  has_many :network_auditors, -> { where "joined_at IS NOT NULL" }, class_name: :PatientNetwork, inverse_of: :granter_patient, foreign_key: :granter_patient_id
  has_many :network_granters_pending, -> { where "joined_at IS NULL" }, class_name: :PatientNetwork, inverse_of: :auditor_patient, foreign_key: :auditor_patient_id
  has_many :network_granters, -> { where "joined_at IS NOT NULL" }, class_name: :PatientNetwork, inverse_of: :auditor_patient, foreign_key: :auditor_patient_id

  has_many :coverages, :inverse_of => :patient

  # one day grace period
  has_one :current_coverage, -> {where("'#{Date.today.to_s(:db)}' BETWEEN coverage_start AND (coverage_end + INTERVAL '1 day') AND coverage_status = 'ACTIVE'").order("coverage_end DESC") }, :class_name => 'Coverage'

  #accepts_nested_attributes_for :lifesquares, :allow_destroy => true
  accepts_nested_attributes_for :patient_languages, :allow_destroy => true
  accepts_nested_attributes_for :patient_residences, :allow_destroy => true
  accepts_nested_attributes_for :patient_health_attributes, :allow_destroy => true
  accepts_nested_attributes_for :patient_contacts, :allow_destroy => true
  accepts_nested_attributes_for :patient_insurances, :allow_destroy => true
  accepts_nested_attributes_for :patient_care_providers, :allow_destroy => true
  accepts_nested_attributes_for :patient_health_events, :allow_destroy => true
  accepts_nested_attributes_for :patient_therapies, :allow_destroy => true
  accepts_nested_attributes_for :patient_allergies, :allow_destroy => true
  accepts_nested_attributes_for :patient_medical_facilities, :allow_destroy => true
  accepts_nested_attributes_for :patient_pharmacies, :allow_destroy => true
  #accepts_nested_attributes_for :care_providers
  accepts_nested_attributes_for :provider_credentials, :allow_destroy => true

  # Columns

  if self.respond_to?(:set_date_columns)
    set_date_columns :birthdate, :photo_date
    set_date_columns :weight_measurement_date
    set_date_columns :height_measurement_date
    set_date_columns :maternity_due_date
  end

  #at could also whitelist globally with config.active_record.whitelist_attributes = true
  # nested attrs need whitelisting as well
  # http://sachachua.com/blog/2011/05/rails-paperclip-attributes-defined-attr_accessible-attr_accessor/
  # http://apidock.com/rails/ActiveRecord/NestedAttributes/ClassMethods/accepts_nested_attributes_for
  attr_readonly :patient_id, :create_date, :create_user
  # attr_accessible :birthdate,:first_name,:last_name,:middle_name,:patient_uid_country,:patient_uid_country_origin,:patient_uid_state,
  #   :patient_uid_state_origin,:notes,:name_prefix,:name_suffix,:pulse,:bp_systolic,:bp_diastolic,:gender,:eye_color_both,:eye_color_left,:eye_color_right,:weight,:height,
  #   :weight_measurement_date,:height_measurement_date,:hair_color,:blood_type,:ethnicity,:photo_date,:preferred_name,:maternity_due_date,
  #   :medication_presence,:allergy_presence,:condition_presence,:immunization_presence,:procedure_presence,:directive_presence,:maternity_state,:confirmed,
  #   :patient_languages_attributes,:patient_residences_attributes,:patient_health_attributes_attributes,:patient_contacts_attributes,
  #   :patient_insurances_attributes,:patient_care_providers_attributes,:patient_health_events_attributes,:patient_therapies_attributes,
  #   :patient_allergies_attributes,:patient_medical_facilities_attributes,:patient_pharmacies_attributes,:provider_credentials_attributes,
  #   :maternity_due_date_mask, :organ_donor, :biometrics_privacy, :demographics_privacy, :searchable, :immunization_presence, :status,
  #   :as => [:default,:admin]

  # attr_accessible :photo, :photo_uid, :photo_thumb_crop_params, :lifesquares_attributes,
  #   :lifesquare_ids, :remove_photo, :retained_photo,
  #   :as => :admin

  def self.get_permitted_params
      return [:first_name, :last_name, :middle_name, :name_suffix,
        :birthdate, :organ_donor, :searchable, :demographics_privacy,
        :gender, :ethnicity, :biometrics_privacy, :hair_color,
        :eye_color_both, :blood_type, :height, :weight,
        :bp_systolic, :bp_diastolic, :pulse, :maternity_due_date]
  end

  # Validations

  validates :birthdate, :presence => true

  validates :first_name, :length => {:maximum => 50} #,:presence => true
  validates :last_name, :length => {:maximum => 50} #, :presence => true

  validates :name_prefix, :length => {:maximum => 50}
  validates :name_suffix, :length => {:maximum => 50}

  validates :eye_color_both, :length => {:maximum => 30}
  validates :eye_color_left, :length => {:maximum => 30}
  validates :eye_color_right, :length => {:maximum => 30}

  validates :hair_color, :length => {:maximum => 30}

  # TODO: validators on pulse and bp_systolic, bp_diastolic why not

  # weight in Kg
  validates :weight, :numericality => { :greater_than => 0, :less_than => 500 }, :allow_nil => true
  # height in cm
  validates :height, :numericality => { :greater_than => 0, :less_than => 300 }, :allow_nil => true

  validates :preferred_name, :length => {:maximum => 50}
  validates :middle_name, :length => {:maximum => 50}

  validates :patient_uid_country, :length => {:maximum => 30}

  validates :patient_uid_state, :length => {:maximum => 30}

  validates :patient_uid_state_origin, :length => {:maximum => 50}

  validates :notes, :length => {:maximum => 4000}

  # Requires the validates_timeliness library
  #at though it's possible expecting parents may want to setup a lifesquare for an upcoming birthdate
  # validates_date :birthdate, :on_or_before => :today
  #validates_date :birthdate, :on_or_before => lambda { Date.current }

  validates_date :weight_measurement_date, :on_or_before => :today, :allow_nil => true, :allow_blank => true,
    :if => :weight_measurement_date_changed?
  validates_date :height_measurement_date, :on_or_before => :today, :allow_nil => true, :allow_blank => true,
    :if => :height_measurement_date_changed?

  validates_date :photo_date, :on_or_before => :today, :allow_nil => true, :allow_blank => true,
    :if => :photo_date_changed?
  validates_date :maternity_due_date, :on_or_after => lambda { 2.days.ago }, :allow_nil => true, :allow_blank => true,
    :if => :maternity_due_date_changed?

  validate :maternity_state_and_due_date

  # validate :ui_confirmation_history_presence

  # TODO: specific privacy validations - can't use the mixin here because it was bound to the privacy attribute, bla

  def maternity_state_and_due_date
    errors[:base] << 'Due date required if pregnancy indicated' unless
      maternity_state? ? self[:maternity_due_date].present? : self[:maternity_due_date].blank?
  end

  def ui_confirmation_history_presence
    errors[:base] << 'Need medical history before confirming a profile record' unless confirmed? ?
      (self[:medication_presence].present? && self[:allergy_presence].present? &&
      self[:condition_presence].present? && self[:immunization_presence].present? &&
      self[:procedure_presence].present? && self[:directive_presence].present?) : true
  end

  before_validation do
    self[:maternity_due_date] = nil if !maternity_state? && self[:maternity_due_date].present?
  end

  after_initialize do
    self[:birthdate] ||= ''
    self[:first_name] ||= ''
    self[:last_name] ||= ''
  end

  after_touch do
    ##:clear_association_cache
    ## ^this a the nuke, but only the patient_network is touching us right now, so...
    # TODO: this will break in rails 5.1
    # Charles: tell me what you're trying to achieve with this
    network_auditors(true)
    network_granters(true)
  end

  def preassign_pk
    # could also check driver from connection_config?
    self[:patient_id] = connection.next_sequence_value(self.class.sequence_name) if connection.respond_to?(:next_sequence_value) && !self[:patient_id].present?
  end

  def self.account_authorized_patient(account_id, patient_id)
    # TODO: rename this method, and why the heck is it a model method at all??? nothing to DRY up here!
    where(:account_id => account_id, :patient_id => patient_id).first
  end

  def self.account_authorized_patients(account_id)
    # TODO: rename this method and adjust the 3 calling locations
    where(:account_id => account_id, :status => 'ACTIVE').order("create_date")
  end

  def organization
    organization = nil
    patient_lifesquare = self.lifesquare
    campaign = patient_lifesquare.campaign if patient_lifesquare
    organization = campaign.organization if campaign
    organization
  end

  def conditions
    patient_health_events.select { |e| e.condition? }
  end

  def immunizations
    patient_health_events.select { |e| e.immunization? }
  end

  def procedures
    patient_health_events.select { |e| e.procedure? }
  end

  def medications
    patient_therapies
  end

  def alerted_medications
    medications.select { |m| m.is_flagged }
  end

  def allergies
    patient_allergies
  end

  def destroy
    self.lifesquares.try(:each) do |l|
      l.patient_id = nil
      l.valid_state = 10
      l.save!
    end
    super
  end

  def fullname
    # return New Profile
    if self[:first_name] == '' and self[:last_name] == ''
      return "New Profile"
    end
    items = []
    if self[:first_name] != nil
      items.push(self[:first_name])
    end
    if self[:middle_name] != nil
      items.push(self[:middle_name])
    end
    if self[:last_name] != nil
      items.push(self[:last_name])
    end
    if self[:name_suffix] != nil
      items.push(self[:name_suffix])
    end
    return items.join(' ')
  end

  def name_extended
    if self[:first_name] == '' and self[:last_name] == ''
      return "New Profile"
    end
    items = []
    if self[:first_name] != nil
      items.push(self[:first_name])
    end
    if self[:middle_name] && self[:middle_name].length > 0
      items.push('%s.' % [self[:middle_name][0]])
    end
    if self[:last_name] != nil
      items.push(self[:last_name])
    end
    return items.join(' ')
  end

  def dob_to_s
    birthdate.strftime('%m-%d-%Y')      # todo localization
  end

  def dob_to_s_slashes
    birthdate.strftime('%m/%d/%Y')
  end

  def email
    #accounts.first.email # @@@ LAME [2014.07.23 christopheraugustus] LOVE YOUR STYLE CAT MANG [2016.05.13 charlesmastin]
    account.email
  end

  def notes_html
    self.notes.gsub(/[\r\n]+/, "<br>").html_safe unless !self.notes?
  end

  def invite_into_network(auditor_patient, attributes = {}) # returns a newly created PatientNetwork, or nil
    if !auditor_patient
      fail_with_error 'no patient specified to be invited to your network'
    elsif network_auditors.exists? granter_patient_id: patient_id, auditor_patient_id: auditor_patient.patient_id
      fail_with_error "patient #{auditor_patient.fullname} is already in your network"
    elsif !(patnet = PatientNetwork.create!(
                      {granter_patient_id:  patient_id,
                      auditor_patient_id:   auditor_patient.patient_id,
                      joined_at:            DateTime.now}
                      .merge(attributes)))
      fail_with_error "failed to invite patient #{auditor_patient.fullname} into your network"
    else
      patnet
    end
  end

  def ask_to_join_network(granter_patient, attributes = {}) # returns a newly created PatientNetwork, or nil
    if !granter_patient
      fail_with_error 'no patient specified to join his/her network'
    elsif network_granters.exists? granter_patient_id: granter_patient.patient_id, auditor_patient_id: patient_id
      fail_with_error "you are already in the network of patient #{granter_patient.fullname}"
    elsif !(patnet = PatientNetwork.create!(
                      {granter_patient_id:  granter_patient.patient_id,
                       auditor_patient_id:  patient_id,
                       asked_at:            DateTime.now}
                      .merge(attributes)))
      fail_with_error "failed to ask to join network of patient #{granter_patient.fullname}"
    else
      patnet
    end
  end

  def decline_network(auditor_patient)

  end

  def accept_into_network(auditor_patient, privacy)
    if !auditor_patient
      fail_with_error 'no patient specified to be accepted into your network'
    elsif !(patnet = network_auditors_pending.find_by_granter_patient_id_and_auditor_patient_id(patient_id, auditor_patient.patient_id))
      fail_with_error "#{auditor_patient.fullname} is not asking to join your network"
    elsif patnet.joined_at
      fail_with_error "#{auditor_patient.fullname} already joined your network on #{patnet.joined_at}"
    else
      patnet.joined_at = DateTime.now
      patnet.privacy = privacy
      patnet.save
      patnet
    end
  end

  def get_details(scope)
    # TODO: use direct AR references / association attributes on the lookups, OMG
    details = {

    }

    if scope == 'personal' || scope == '*'
      languages = PatientLanguage.where(patient_id: self.patient_id).to_a
      languages.sort! {|a, b| a.record_order <=> b.record_order}
      details['languages'] = languages
      details['addresses'] = PatientResidence.where(patient_id: self.patient_id).order('create_date') # record_order implies sortable UI
    end

    # new
    if scope == 'documents' || scope == 'medical' || scope == '*'
      # TODO: very temporary, move back to model son, however this query is the central access point for things at the moment
      all_dd = PatientHealthAttribute.directives_by_patient_id(self.patient_id)
      directives = []
      documents = []
      all_dd.each_with_index do |document, index|
        # learn to use the enums correctly SUCKA
        if document and document.document_digitized
          if Values.call('directive').collect{|item| item[:value]}.include? document.document_digitized.category
            directives.push(document)
          end
          if Values.call('document').collect{|item| item[:value]}.include? document.document_digitized.category
            documents.push(document)
          end
        end
      end
      details['documents'] = documents
      details['directives'] = directives
    end

    if scope == 'medical' || scope == '*'
      details['medications'] = PatientTherapy.where(patient_id: self.patient_id)
      details['allergies'] = PatientAllergy.where(patient_id: self.patient_id)
      details['conditions'] = PatientHealthEvent.conditions_by_patient_id(self.patient_id)
      details['immunizations'] = PatientHealthEvent.immunizations_by_patient_id(self.patient_id)
      details['procedures'] = PatientHealthEvent.procedures_by_patient_id(self.patient_id)
      details['alert_medications'] = []
      details['medications'].each do |m|
        if m.is_flagged
          details['alert_medications'].push m
        end
      end
    end

    if scope == 'contacts' || scope == '*'
      details['emergency'] = PatientContact.nonself_by_patient_id(self.patient_id).order('create_date')
      details['insurances'] = PatientInsurance.where(patient_id: self.patient_id)
      details['care_providers'] = PatientCareProvider.where(patient_id: self.patient_id)
      details['hospitals'] = PatientMedicalFacility.hospitals_by_patient_id(self.patient_id)
      details['pharmacies'] = PatientPharmacy.where(patient_id: self.patient_id)
    end

    # if permission check is enabled? pass it on this seems sketchy, but what the hell, it's currently the lowest location to do it

    return details

  end

  def view_permission_for_account(account)
    permission = 'public'
    permission_index = 0
    # if we're owner break
    if self.account_id == account.account_id
      return 'private'
    end
    # if we have a network connection
    # edge case, provider has elevated permissions UI prevents leveling down
    if account.provider?
      permission = 'provider'
      permission_index = 1
    end
    privacy_stack = Values.call('privacy')
    auth_patients = Patient.where(:account_id => account.account_id, :status => 'ACTIVE')
    for _ap in auth_patients
      connection = PatientNetwork.where(:granter_patient_id => self.patient_id, :auditor_patient_id => _ap.patient_id).first
      if connection != nil
        privacy_stack.each_with_index do |p, i|
          if p[:value] == connection.privacy && i > permission_index
            permission_index = i
            permission = connection.privacy
          end
        end
      end
    end    
    permission
  end

  def self.obj_has_view_permission(obj, permission, privacy_attribute='privacy')
    # TODO: more eloquent solution? it works
    # this is assumed to be the owner of the data, or having been granted increased permissions
    if permission == 'private'
      return true
    end
    # most common scenario
    if permission == 'provider'
      begin
        if ['provider', 'public'].include? obj[privacy_attribute]
          return true
        end
      rescue Exception => e
      end
    end
    if permission == 'public'
      begin
        if obj[privacy_attribute] == 'public'
          return true
        end
      rescue
      end
    end
    return false
  end

  def get_mailing_residence
    residence = nil
    residence = PatientResidence.where(:patient_id => self.patient_id, :mailing_address => true).first
    if residence == nil
      residence = PatientResidence.where(:patient_id => self.patient_id, :residence_type => 'HOME').first
      if residence == nil
        residence = PatientResidence.where(:patient_id => self.patient_id).first
        if residence == nil
          # NOT HERE SON
          # go up to the account, find the first patient, not me, and repeat the process?, infinite loops on your loops, or no?
        end
      end
    end
    residence
  end

  def get_printable_address
    residence = get_mailing_residence
    # do the going up part here to avoid internal looptown sucking
    if residence == nil
      if self.account.active_patients.length > 1 && self.account.active_patients[0] != self
        residence = self.account.active_patients[0].get_mailing_residence
      end
    end
    lines = []
    if residence != nil
      lines.push(residence.address_line1.strip) if residence.address_line1.present?
      lines.push(residence.address_line2.strip) if residence.address_line2.present?
      lines.push(residence.address_line3.strip) if residence.address_line3.present?
      s = ""
      s += residence.city.strip if residence.city.present?
      if residence.state_province.present?
        s += ", " if residence.city.present?
        s += residence.state_province.strip
      end
      if residence.postal_code.present?
        s += " " if residence.city.present? or residence.state_province.present?
        s += residence.postal_code.strip
      end
      lines.push(s) if s.present?
    end
    return lines.join("\n")
  end

  after_save :publish_update

private

  def fail_with_error(string_error)
    puts "### ERROR: #{string_error}"
    errors[:base] << string_error
    nil
  end

  def publish_update
    # require 'pubnub'
    # pubnub = Pubnub.new(
    #   publish_key: Rails.application.config.pubnub[:publish_key],
    #   subscribe_key: Rails.application.config.pubnub[:subscribe_key]
    # )

    # pubnub.publish(
    #   channel: 'patient-' + self.uuid,
    #   message: 'update'
    # ) do |envelope| 
    #   puts envelope.parsed_response
    # end
  end

end
