# TODO: ultimately need to handle the rise of lifesquare providers - and have a link to said official records...
# vs having patients randomly enter random john, does all day long

class PatientCareProvider < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_pcp

  enum care_provider_class: {
    allergy: 'ALLERGY',
    cardio: 'CARDIO',
    derm: 'DERM',
    endo: 'ENDO',
    ent: 'ENT',
    gensurg: 'GENSURG',
    hemat: 'HEMAT',
    hepat: 'HEPAT',
    infect: 'INFECT',
    nephro: 'NEPHRO',
    neurol: 'NEUROL',
    neurosurg: 'NEUROSURG',
    obgyn: 'OBGYN',
    onco: 'ONCO',
    ophth: 'OPHTH',
    other: 'OTHER',
    pain: 'PAIN',
    peds: 'PEDS',
    plastics: 'PLASTICS',
    primary: 'PRIMARY',
    psych: 'PSYCH',
    pulm: 'PULM',
    radonc: 'RADONC',
    rheuma: 'RHEUMA',
    thoracic: 'THORACIC',
    transpl: 'TRANSPL',
    urology: 'UROLOGY',
    vascsurg: 'VASCSURG',
    cardiosurg: 'CARDIOSURG',
    ortho: 'ORTHO',
    gastro: 'GASTRO',
    geriatric: 'GERIATRIC'
  }

  def self.formatted_care_provider_classes
    {
      'ALLERGY' => 'Allergy / Immunology',
      'CARDIO' => 'Cardiology',
      'DERM' => 'Dermatology',
      'ENDO' => 'Endocrinology',
      'ENT' => 'ENT / Otolaryngology',
      'GENSURG' => 'General Surgery',
      'HEMAT' => 'Hematology',
      'HEPAT' => 'Hepatology',
      'INFECT' => 'Infectious Disease',
      'NEPHRO' => 'Nephrology',
      'NEUROL' => 'Neurology',
      'NEUROSURG' => 'Neurosurgery',
      'OBGYN' => 'OB/GYN',
      'ONCO' => 'Oncology',
      'OPHTH' => 'Ophthalmology',
      'OTHER' => 'Other',
      'PAIN' => 'Pain Management',
      'PEDS' => 'Pediatrics',
      'PLASTICS' => 'Plastic Surgery',
      'PRIMARY' => 'Primary Care',
      'PSYCH' => 'Psychiatry',
      'PULM' => 'Pulmonology',
      'RADONC' => 'Radiation Oncology',
      'RHEUMA' => 'Rheumatology',
      'THORACIC' => 'Thoracic Surgery',
      'TRANSPL' => 'Transplant Surgery',
      'UROLOGY' => 'Urology',
      'VASCSURG' => 'Vascular Surgery',
      'CARDIOSURG' => 'Cardiothoracic Surgery',
      'ORTHO' => 'Orthopedic Surgery',
      'GASTRO' => 'GI / Gastroenterology',
      'GERIATRIC' => 'Geriatrics'
    }
  end

  attr_readonly :patient_care_provider_id, :patient_id, :create_user, :create_date
  # attr_accessible :record_order, :first_name, :last_name, :title, :care_provider_class, :middle_name,
  #   :phone1, :phone2, :email, :address_line1, :city, :state_province, :country, :postal_code, :address_line2, :address_line3,
  #   :medical_facility_name, :privacy,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id,
  #   :as => :admin

  # Table relationships

  def name
    (self[:first_name].present? ? "#{self[:first_name]} " : '') + self[:last_name]
  end

  def class_title
    # TODO: this is janktown
    if self[:care_provider_class].present? && self[:title].present?
      "#{self.formatted_care_provider_classes[self[:care_provider_class]]}, #{self[:title]}"
    elsif self[:care_provider_class].present?
      self.formatted_care_provider_classes[self[:care_provider_class]]
    elsif self[:title].present?
      self[:title]
    end
  end
  
  # Table relationships

  belongs_to :patient, :inverse_of => :patient_care_providers

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations
  
  validates :first_name, :length => {:maximum => 50}

  validates :last_name, :length => {:maximum => 50}, :presence => true

  validates :title, :length => {:maximum => 50}

  validates :middle_name, :length => {:maximum => 50}
  # format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ }, 
  validates :phone1, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true
  validates :phone2, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true
  validates :email, :length => {:maximum => 100}
  validates :address_line1, :length => {:maximum => 150}
  validates :city, :length => {:maximum => 50}
  validates :state_province, :length => {:maximum => 50}
  validates :country, :length => {:maximum => 2}
  validates :postal_code, :length => {:maximum => 15}
  validates :address_line2, :length => {:maximum => 100}
  validates :address_line3, :length => {:maximum => 100}

  # TODO: remove me after code to set country is in place
  # and all country data has been populated in the database
  after_find :initialize_country
  def initialize_country
    self[:country] = self[:country].presence || 'US' if self[:state_province].presence
  end

  # API precomputed title/description for common consumption
  def title
    "#{self.first_name} #{self.last_name}"
  end

  def description
    begin
      self.care_provider_class.present? ? PatientCareProvider.formatted_care_provider_classes[self.care_provider_class] : ""
    rescue
    end
  end

  def phone
    self.phone1
  end

  def as_json_care_provider_class
    self.care_provider_class.present? ? PatientCareProvider.care_provider_classes[self.care_provider_class] : ""
  end

  def as_json(options = { })
    # TODO: temp crash avoidance measure
    # somehow we had a null on state
    # null on state with country non us causes iOS crash
    super(options).merge({:title => title, :description => description, :care_provider_class => as_json_care_provider_class })
  end

end
