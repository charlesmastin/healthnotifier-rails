class Account < ApplicationRecord
  self.sequence_name = :seq_account

  # TODO: the why in why we need this, like it doesn't really do much
  # we need the ability to disable accounts that's one thing
  # having active / inactive is silly, honestly
  enum account_status: {
    active: 'ACTIVE',
    # inactive: 'INACTIVE', #
    disabled: 'DISABLED', # 
    deleted: 'DELETED' # DAAAAAAAAAAAAAAAAAAAALETED!
  }

  # this notion is wrong, but we'll save that battle for another day
  enum account_type: {
    patient: 'PATIENT',
    provider: 'PROVIDER'
  }

  # this is in use in legacy, but not current, we'll persist for fun times
  enum signup_refer: {
    community_group: 'COMMUNITY',
    cvs: 'CVS',
    online_ad: 'EAD',
    facebook: 'FACEBOOK',
    twitter: 'TWITTER',
    friend_or_family_member: 'FRIENDFAM',
    newspaper_ad: 'NEWSAD',
    newspaper_article: 'NEWSART',
    other: 'OTHER',
    marin_mailing: 'WATER',
    whistlestop: 'WHSTLSTP'
  }

  # bla bla, origin platform oracle yourself
  # even for someone who splits the acccount off
  # the claiming party will consume on a particular first platform
  # in a very round-about way one could run a report at Keen and get this info based on account creation
  # LOLINATORS™
  enum signup_platform: {
    signup_web: 'WEB', # which is also MOBILE, it's all the same son 
    # mobile: 'MOBILE', 
    signup_native_ios: 'NATIVE_IOS',
    signup_native_android: 'NATIVE_ANDROID'
    # indirect: when the time comes
    # provisioned: when the time comes
  }

  # Associations
  has_many :patients, -> { order 'create_date asc' }

  def active_patients
    patients.select { |p| p.active? }
  end

  def deleted_patients
    patients.select { |p| !p.active? }
  end

  def this_is_me_maybe
    self.active_patients.first
  end

  # has_many :active_patients, class_name: 'Patient', primary_key: 'account_id', foreign_key: 'patient_id' # -> { where(status: 'ACTIVE')
  has_many :payments, :through => :patients
  has_many :audits, class_name: 'Audit', primary_key: 'account_id', foreign_key: 'scanner'

  if self.respond_to?(:set_boolean_columns)
    set_boolean_columns :optin_email_marketing
  end

  devise :uid, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :confirmable, :lockable, :timeoutable,
         :authentication_keys => [:email]

  # Setup accessible (or protected) attributes for your model
  
  # attr_accessible :email, :password, :current_password, :password_confirmation, :accept_terms,
  #   :remember_me, :account_type,:account_status, :optin_email_marketing,
  #   :terms_of_use, :signup_platform, :exit_survey

  validates :email, :presence => true
  validates :email,
            :uniqueness => {:message => "address is already in use. <a href=\"/login\">Log in</a> to that account, or enter a different email address."},
            :email_format => {},
            :if => :email_changed?
  validates :accept_terms, :acceptance => { :accept => "1", :message => 'you must accept the terms of this service' },
    :if => :new_record?
  validates :password, :presence => true,
    :format => { :with => /[\d\W_]/,
    :message => 'must include at least one number or non-letter symbol' },
    :length => { :in => 8..128 },
    :if => :password_required?
  validates_confirmation_of :password, :if => :password_confirmation_required?

  validates :terms_of_use, :inclusion => { :in => [Rails.configuration.tou_version] }, :if => :terms_of_use_changed?

  validates :account_status, :presence => true
  validates :account_type, :presence => true

  def uuid
    self.uid
  end

  # NEW TEMP TOKEN CODE

  def provision_token
    # creates a new token for this account
    # use the greatest hits of our existing systems to generate
    # set dat expiration though
    # expire old tokens?

    # FML
    loop do
      new_token = SecureRandom.uuid#Devise.friendly_token
      break new_token unless AccountToken.where(token: new_token, account_id: self.account_id, account_device_id: nil).first
    end
  end

  def update_token_with_device_id
    # meh, this could be somew
    # here else though, this is just a silly town helper
  end

  def destroy_token
    # a specific token
  end

  def destroy_all_tokens
    tokens = AccountToken.where(:account_id => self.account_id)
    tokens.each do |token|
      token.destroy!
    end
  end

  def destroy_tokens
    # destroys all tokens for this account
    tokens = AccountToken.where(:account_id => self.account_id, :account_device_id => nil)
    tokens.each do |token|
      token.destroy!
    end
  end

  def get_account_token
    # lolzin, get's the legacy style single token per device
    # aka, look into the AccountToken and find where the account is this, and device_id is null yea son
    # string or nil
    # meh, not sure if we should handle the notion of expired tokens at this point, but I think we return nil if the token is trashed
    # unlikely though, but will naturally cause a client to re-authenticate
    # Subscription.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day)
    token = AccountToken.where("account_id = ? AND account_device_id IS NULL AND DATE(expires_at) > NOW()", self.account_id).first
    if token == nil
      return nil
    end
    token.token
  end


  # increase the timeout for lifesquare accounts
  # to allow for anything that may take a long time
  # (e.g., editing care plans)
  def timeout_in
    lifesquare_employee? ? 1.days : Devise.timeout_in
  end

  # THIS IS NOT USED IN CODE, JUST OLD CA SPECS WHICH ARE OLD
  def approved_provider?
    # TODO: THIS NEEDS OVERHAULIN SON
    patients.each do |pat|
      return true if pat.provider_credentials[0].try(:status_accepted?)
    end
    false
  end

  def establish_provider(be_provider)
    # TODO: use new enum
    accttypenew = be_provider ? 'PROVIDER' : 'PATIENT' # TODO: @@@ YUCKY duplication
    update_attributes(account_type: accttypenew) unless account_type == accttypenew
  end

  def lifesquare_employee?
    return (self.email.include? "lifesquare.com" and self.confirmed_at != nil)
  end

  # organization AR hacks bro
  # NAIIVE FOR NOW
  # later we need to manage the permission stacking, like we do for other things
  
  
  def owner_orgs
    get_orgs_by_membership "OWNER"    
  end

  def admin_orgs
    get_orgs_by_membership "ADMIN"
  end

  def member_orgs
    # TODO: this could honestly be complicated, depending on if we ever create basic memberships
    # should it be inclusive
    get_orgs_by_membership "MEMBER"
  end

  # move to private scope though
  def get_orgs_by_membership(role)
    # check for active status though
    orgs = []
    memberships = AccountOrganization.where(:account_id => self.account_id, :role => role, :status => "ACTIVE")
    memberships.each do |membership|
      # TODO: handle deleted orgs though
      orgs.append(membership.organization)
    end
    orgs
  end

  # def destroy
    # TODO: wipe all the nested patients, if our FK doesn't insist on that
    # EXCEPT OMG, deleting all the patient data, we must instead set to delete or something, never delete never never never
  # end

  after_initialize do
    # TODO: why why why why why why, but this case seems like it can't happen? or can it, due to validation error, LOL, which means creating account will fail, potentially
    self[:account_status] = 'ACTIVE' if self[:account_status].blank?
    self[:account_type] = 'PATIENT' if self[:account_type].blank?
  end

  before_create do
    self[:update_user] ||= 2
    self[:create_user] ||= 2
    self[:email].downcase!
    self[:terms_of_use] = Rails.configuration.tou_version
  end

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def password_confirmation_required?
    persisted? && password_required?
  end

  # TODO: WTF
  def send_campaign_coverage_renewal_reminder(patient, coverage_end, campaign)
    date_string_for_display = coverage_end.strftime("%Y-%m-%d")
    subject = "Lifesquare account for #{patient.name} is going to expire on #{date_string_for_display}"
    AccountMailer.send_email(self[:email], subject, 'accounts/mailer/coverage_renewal', {:patient => patient,
                                                                                         :coverage_end => date_string_for_display,
                                                                                         :campaign => campaign}).deliver_later
  end

  # TODO: WTF
  def send_non_campaign_coverage_renewal_reminder(patient, coverage_end)
    date_string_for_display = coverage_end.strftime("%Y-%m-%d")
    subject = "Lifesquare account is going to expire on #{date_string_for_display}"
    AccountMailer.send_email(self[:email], subject, 'accounts/mailer/coverage_renewal', {:patient => patient,
                                                                                         :coverage_end => date_string_for_display}).deliver_later
  end

  def get_available_cards
    cards = []
    if self.stripe_customer_id
      if customer = self.stripe_customer
        begin
          # it appears there are 2 ways to obtain existing card references
          # TODO: check this against the historical customers, although not that big of a deal
          begin
            customer[:cards][:data].each do |card|
              cards.push(card)
            end
          rescue
          end
          begin
            customer[:sources][:data].each do |card|
              cards.push(card)
            end
          rescue
          end
        rescue

        end
      end
    end
    cards
  end

  def stripe_customer
    customer = CreditCardService.get_customer(self.stripe_customer_id)
  end

  belongs_to :campaign

  # this is TEMPORARY™
  def pending_provider_credentials
    if self.patient?
      self.active_patients.each do |p|
        creds = ProviderCredential.where(:patient_id => p.patient_id, :status => 'PENDING')
        if creds.size > 0
          return creds
        end
      end
    end
    []
  end

  def provider_credentials
    if self.provider?
      self.active_patients.each do |p|
        # THIS IS POTENTIALLY / PROBABLY BAD, but we are not permitting multiple provider "patients" in a single "provider" account
        # work the date check logic in here
        # migrate some of the check, lookup from the Ram codebase™
        creds = ProviderCredential.where(:patient_id => p.patient_id, :status => 'ACCEPTED').order('created_at').first
        if creds != nil
          return creds
        end
      end
    end
    nil
  end

  def pending_invites
    # just a count for now, keep dat perf low son - optimize later #jerrytown
    # iterate active patients and scoop the patientnetwork for pending balblablablabla
    # totally unsure, need ux solved, don't care on perf now
    # return 0
    invites = []
    self.active_patients.each do |p|
      invites += p.network_auditors_pending
    end
    invites
  end

  # look up those pesky credentials here, vs patient, vs wherever, given we need to access from the account context

  # has_many :account_patients, :inverse_of => :account, :dependent => :destroy
  # has_many :patients, :through => :account_patients

  # accepts_nested_attributes_for :account_patients, :allow_destroy => true
  # accepts_nested_attributes_for :patients, :allow_destroy => true

  def legacy_api_json
    # this is the historical representation, dry'd up doh
    # temp variables in the event someone doesn't have patients, which would cause a lookup fail for the name
    first_name = ''
    last_name = ''
    cred_status = nil
    provider = false


    # try to grab the first patient and fill the name, ironically this part of the API is no longer used!
    begin
      patient = Patient.where(:account_id => self.account_id, :status => 'ACTIVE').order('create_date').first
      first_name = patient.first_name
      last_name = patient.last_name
      # STOP WITH THIS NONSENSE
    rescue
      # we don't have an active account, this is really more like a 500
      # return nil
      # no this is not a case, because we can be a "business" account which doesn't have a patient yet
      # or an account that deleted all their patients and is resuming
    end
    # quick/dirty permissions

    permissions = ["scan"]
    
    # if ACCOUNT.provider? then skip the crap and say we're ACCEPTED because we are
    if self.provider?
      # this is legacy
      permissions = ["scan", "search", "nearby"]
      provider = true
      cred_status = "ACCEPTED" # or is it accepted???? meh
    else
      begin
        # TODO: total horse piles, this is a lot of donkey work, just to show status
        # and we're literally looking at all kinds of terrible edge cases
        # go through all patients for account
        # go through all credetnails for those patients, sorted by date
        # get the First item (aka most recent) for each patient for account

        # ok, grab the patient_ids
        # do a select in [1,2,3,4] ordered bro
        # or not, patient_ids shows deleted patients, eemmmmm, f
        credentials = []
        self.active_patients.each do |patient|
          creds = ProviderCredential.where(:patient_id => patient.patient_id).order('updated_at').first
          if creds != nil
            credentials.append(creds)
          end
        end
        if credentials.length > 0
          # sort again though, FML
          credentials = credentials.sort_by(&:updated_at).reverse
          cred_status = credentials[0].status
        end
      rescue
        # provider_creds = ProviderCredential.where(:patient_id => patient.patient_id).order('created_at').first
        # cred_status = provider_creds ? provider_creds.status : nil 
      end
    end

    return {
      :AuthToken => self.get_account_token, # some transitional crap here, to bridge the gaps between old and new
      :Provider => provider,
      :ProviderCredentialStatus => cred_status,
      :Permissions => permissions,
      :FirstName => first_name,
      :LastName => last_name,
      :Email => self.email,
      :MobilePhone => self.mobile_phone, # stopgap
      :AccountId => self.uid,
      :PatientsCount => Patient.where(:account_id => self.account_id, :status => 'ACTIVE').count
    }
  end

end
