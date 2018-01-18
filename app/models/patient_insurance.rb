class PatientInsurance < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_patient_insurance

  enum insurance_type: {
    medical: 'MEDICAL'
  }

  alias_attribute :name, :organization_name

  attr_readonly :patient_insurance_id, :patient_id, :create_user, :create_date
  # attr_accessible :record_order, :policy_code, :organization_name, :phone, :group_code, :health_plan_code,
  #   :policyholder_first_name, :policyholder_last_name, :effective_date, :expire_date, :insurance_type, :privacy,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id, :insurance_type,
  #   :as => :admin

  if self.respond_to?(:set_date_columns)
    set_date_columns :expire_date, :effective_date
  end

  # Table relationships

  belongs_to :patient, :inverse_of => :patient_insurances

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations
  
  validates :policy_code, :length => {:maximum => 30}
  validates :group_code, :length => {:maximum => 30}
  validates :health_plan_code, :length => {:maximum => 30}
  validates :policyholder_first_name, :length => {:maximum => 100}
  validates :policyholder_last_name, :length => {:maximum => 100}
  validates :organization_name, :length => {:maximum => 100}, :presence => true
  # :format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ }, 
  validates :phone, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true

  def policyholder_name
    if self[:policyholder_first_name].present? and self[:policyholder_last_name].present?
      "#{self[:policyholder_first_name]} #{self[:policyholder_last_name]}"
    else  # At least one is empty
      "#{self[:policyholder_first_name]}#{self[:policyholder_last_name]}"
    end
  end

  validates_date :effective_date, :allow_nil => true, :allow_blank => true
  validates_date :expire_date, :allow_nil => true, :allow_blank => true

  # API precomputed title/description for common consumption
  def title
    "#{self.organization_name}"
  end

  def description
    ""
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description})
  end

end
