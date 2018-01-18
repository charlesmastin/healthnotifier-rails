class PatientPharmacy < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_patient_pharmacy

  attr_readonly :patient_pharmacy_id, :patient_id, :create_user, :create_date
  # attr_accessible :record_order, :name, :phone, :url, :address_line1, :city, :state_province, :country, :postal_code,
  #   :address_line2, :address_line3, :privacy,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id,
  #   :as => :admin

  # Table relationships

  belongs_to :patient, :inverse_of => :patient_pharmacies

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id

  # Validations
  
  validates :name, :length => {:maximum => 100}, :presence => true

  validates :address_line1, :length => {:maximum => 150}
  # :format => { :with => /\A\+?[0-9]{10,}(x[0-9]+)?\z/ },
  validates :phone, :length => {:maximum => 30}, :allow_nil => true, :allow_blank => true
  validates :url, :length => {:maximum => 100}
  validates :city, :length => {:maximum => 50}
  validates :state_province, :length => {:maximum => 50}
  validates :postal_code, :length => {:maximum => 15}
  validates :country, :length => {:maximum => 2}
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
    "#{self.name}"
  end

  def description
    "#{self.city}, #{self.state_province}"
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description})
  end

end
