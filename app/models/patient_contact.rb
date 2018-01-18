class PatientContact < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_patient_contact

  # TODO: call this simply relationship?
  # non namespacing will allow for trivial uppercase matching inside the backbone setup, terrible but a timesaver
  enum contact_relationship: {
    aunt: 'AUNT',
    brother: 'BROTHER',
    caretaker: 'CARETAKER',
    cousin: 'COUSIN',
    daughter: 'DAUGHTER',
    domestic: 'DOMESTIC',
    father: 'FATHER',
    friend: 'FRIEND',
    gdaughter: 'GDAUGHTER',
    gfather: 'GFATHER',
    gmother: 'GMOTHER',
    gson: 'GSON',
    guardian: 'GUARDIAN',
    husband: 'HUSBAND',
    mother: 'MOTHER',
    nephew: 'NEPHEW',
    niece: 'NIECE',
    other: 'OTHER',
    physician: 'PHYSICIAN',
    relative: 'RELATIVE',
    self: 'SELF',
    sister: 'SISTER',
    so: 'SO',
    son: 'SON',
    spouse: 'SPOUSE',
    uncle: 'UNCLE',
    wife: 'WIFE'
  }

  def self.formatted_contact_relationships
    {
      'AUNT' => 'Aunt',
      'BROTHER' => 'Brother',
      'CARETAKER' => 'Caretaker',
      'COUSIN' => 'Cousin',
      'DAUGHTER' => 'Daughter',
      'DOMESTIC' => 'Domestic Partner',
      'FATHER' => 'Father',
      'FRIEND' => 'Friend',
      'GDAUGHTER' => 'Granddaughter',
      'GFATHER' => 'Grandfather',
      'GMOTHER' => 'Grandmother',
      'GSON' => 'Grandson',
      'GUARDIAN' => 'Guardian',
      'HUSBAND' => 'Husband',
      'MOTHER' => 'Mother',
      'NEPHEW' => 'Nephew',
      'NIECE' => 'Niece',
      'OTHER' => 'Other',
      'PHYSICIAN' => 'Physician',
      'RELATIVE' => 'Relative',
      'SELF' => 'Self',
      'SISTER' => 'Sister',
      'SO' => 'Significant Other',
      'SON' => 'Son',
      'SPOUSE' => 'Spouse',
      'UNCLE' => 'Uncle',
      'WIFE' => 'Wife'
    }
  end

  # TODO: SORT THESE OUT SON for additioanl options
  # Durable Health care\n  Power of Attorney\n| if power_of_attorney?
  # Next of Kin\n| if next_of_kin?
  
  attr_readonly :patient_contact_id, :patient_id, :create_user, :create_date
  # attr_accessible :contact_relationship,:first_name,:home_phone,:mobile_phone,:work_phone,:email,:address_line1,:city,:state_province,
  #   :country,:postal_code,:address_line2,:address_line3,:next_of_kin,:power_of_attorney,:record_order,:last_name, :privacy, :list_advise_send_date,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id,
  #   :as => :admin

  if self.respond_to?(:set_boolean_columns)
    set_boolean_columns :power_of_attorney, :next_of_kin
  end

  def name
    "#{self[:first_name]} #{self[:last_name]}"
  end

  def power_of_attorney?
    Patient.char_truth? self[:power_of_attorney]
  end

  def next_of_kin?
    Patient.char_truth? self[:next_of_kin]
  end

  # Table relationships

  belongs_to :patient, :inverse_of => :patient_contacts

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations
  
  validates :first_name, :length => {:maximum => 100}, :presence => true
  validates :last_name, :length => {:maximum => 100}, :presence => true

  validates :home_phone, :length => {:maximum => 30}, presence: { message: "Valid phone number required" }
  # :format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ },
  #validates :mobile_phone, :format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ }, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true
  #validates :work_phone, :format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ }, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true

  validates :email, :length => {:maximum => 100}

  validates :address_line1, :length => {:maximum => 150}

  validates :city, :length => {:maximum => 50}

  validates :state_province, :length => {:maximum => 50}

  validates :postal_code, :length => {:maximum => 15}

  validates :address_line2, :length => {:maximum => 100}

  validates :address_line3, :length => {:maximum => 100}

  before_validation do
    self[:first_name] = 'Me',self[:last_name] = 'Me' if (self[:first_name].blank? || self[:last_name].blank?) &&
      self[:contact_relationship] == 'SELF'
  end

  # WTF self???
  def self.nonself_by_patient_id(patient_id)
    where(%{patient_id = ? AND (contact_relationship != 'SELF' OR contact_relationship IS NULL)}, patient_id)
  end

  # API precomputed title/description for common consumption
  def title
    "#{self.first_name} #{self.last_name}"
  end

  def description
    # LOLZIN
    PatientContact.formatted_contact_relationships[PatientContact.contact_relationships[self.contact_relationship]]
  end

  def phone
    self.home_phone # TODO blablablablabala
  end

  def as_json_contact_relationship
    PatientContact.contact_relationships[self.contact_relationship]
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description, :contact_relationship => as_json_contact_relationship})
  end

end
