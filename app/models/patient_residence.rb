class PatientResidence < ApplicationRecord
  self.sequence_name = :seq_patient_residence

  # woot this was an exception and was integer based, AND we have to have a formatter, FUN TIMES FRIDAY
  enum lifesquare_location_type: {
    lsq_location_backpack: 'Backpack',
    lsq_location_bracelet: 'Bracelet',
    lsq_location_briefcase: 'Briefcase',
    lsq_location_cane: 'Cane',
    lsq_location_car_window: 'Car Window',
    lsq_location_front_door: 'Front Door',
    lsq_location_helmet: 'Helmet',
    lsq_location_mobilepc: 'Laptop/Tablet',
    lsq_location_lunchbox: 'Lunchbox',
    lsq_location_phone: 'Home Phone',
    lsq_location_mobile_phone: 'Mobile Phone',
    lsq_location_refrigerator: 'Refrigerator',
    lsq_location_walker: 'Walker',
    lsq_location_wallet: 'Wallet',
    lsq_location_other: 'Other'
  }

  # # in a perfect world the numbers would be defined once, but this is easy
  # def self.formatted_lifesquare_location_types
  #   {
  #     1 => 'Backpack',
  #     10 => 'Bracelet',
  #     11 => 'Briefcase',
  #     20 => 'Cane',
  #     30 => 'Car Window',
  #     40 => 'Front Door',
  #     50 => 'Helmet',
  #     51 => 'Laptop/Tablet',
  #     52 => 'Lunchbox',
  #     53 => 'Phone',
  #     54 => 'Mobile Phone',
  #     60 => 'Refrigerator',
  #     70 => 'Walker',
  #     80 => 'Wallet',
  #     1000 => 'Other'      
  #   }
  # end

  # not namespacing allows a basic uppercase comparison inside the js - terrible but easy
  enum residence_type: {
    alf: 'ALF',
    bc: 'BC',
    home: 'HOME',
    other: 'OTHER',
    school: 'SCHOOL',
    snf: 'SNF',
    vacation: 'VACATION',
    work: 'WORK'
  }

  def self.formatted_residence_types
    # well well well, we need a separate lookup on TOP of this, so we can store those sweet CONSTANTS
    {
      'ALF' => 'Assisted Living',
      'BC' => 'Board & Care',
      'HOME' => 'Home',
      'OTHER' => 'Other',
      'SCHOOL' => 'School',
      'SNF' => 'Skilled Nursing',
      'VACATION' => 'Vacation',
      'WORK' => 'Work'
    }
  end

  # json nutter

  def title
    self.address
  end

  def description
    begin
      PatientResidence.formatted_residence_types[PatientResidence.residence_types[self.residence_type]]
    rescue
    end
  end

  ###
  # def lifesquare_location_type
    # self[:lifesquare_location_type] || lifesquare_location_type
  # end

  # RAILS FOR THE FAILS, RAW OYSTER BAR EDITION™
  def as_json(options = { })
    # WOOOOO WOOO, meh meh meh meh meh
    # TODO: hmm, whatev son, kinda a bad idea, but whatever
    options = {:except=>[:latitude, :longitude]}
    # options[:except => [:latitude, :longitude]]
    super(options).merge({:title => title, :description => description,
      :residence_type => PatientResidence.residence_types[self.residence_type],
      :lifesquare_location_type => PatientResidence.lifesquare_location_types[self.lifesquare_location_type]})
  end

  attr_readonly :patient_residence_id, :patient_id, :create_user, :create_date
  # attr_accessible :residence_type,:address_line1,:city,:state_province,
  #   :country,:postal_code,:address_line2,:address_line3,:record_order,:mailing_address, :privacy, :lifesquare_location_type, :lifesquare_location_other,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id,
  #   :as => :admin
  
  if self.respond_to?(:set_boolean_columns)
    set_boolean_columns :mailing_address
  end

  
  
  # for geocoding, etc
  def address
    "#{self[:address_line1]}, #{self[:city]}, #{self[:state_province]}, #{self[:postal_code]}"
  end

  geocoded_by :address

  # Table relationships

  belongs_to :location
  belongs_to :patient, :inverse_of => :patient_residences

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # For rails_admin
  def name
    "#{self[:residence_type]}: #{self[:city]}, #{self[:state_province]}"
  end

  # Validations
  
  validates :address_line1, :length => {:maximum => 150}, :presence => true

  validates :city, :length => {:maximum => 50}, :presence => true

  validates :state_province, :length => {:maximum => 50}, :presence => true

  validates :postal_code, :length => {:maximum => 15}, :presence => true

  validates :address_line2, :length => {:maximum => 100}

  validates :address_line3, :length => {:maximum => 100}

  after_validation :geocode

  # TODO: remove me after code to set country is in place
  # and all country data has been populated in the database
  after_find :initialize_country
  def initialize_country
    self[:country] = self[:country].presence || 'US' if self[:state_province].presence
  end

end
