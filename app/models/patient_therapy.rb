class PatientTherapy < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_patient_therapy

  alias_attribute :name, :therapy

  enum health_event_duration: {
    duration_1week: '1WEEK',
    duration_1month: '1MONTH',
    duration_3month: '3MONTH',
    duration_6month: '6MONTH',
    duration_9month: '9MONTH',
    duration_1year: '1YEAR',
    duration_2year: '2YEAR',
    duration_5year: '5YEAR',
    duration_10year: '10YEAR',
    duration_indefinite: 'INDEFINITE'
  }

  def self.formatted_health_event_durations
    {
      '1WEEK' => 'Within one week',
      '1MONTH' => 'Within one month',
      '3MONTH' => 'Within three months',
      '6MONTH' => 'Within six months',
      '9MONTH' => 'Within nine months',
      '1YEAR' => 'Within one year',
      '2YEAR' => 'Within two years',
      '5YEAR' => 'Within five years',
      '10YEAR' => 'Within ten years',
      'INDEFINITE' => 'Indefinite'
    }
  end

  # wow, raw values in the db, w/e, status quo
  enum therapy_frequency: {
    frequency_as_needed: 'As needed',
    frequency_4_times_per_day: 'Four times per day',
    frequency_3_times_per_day: 'Three times per day',
    frequency_2_times_per_day: 'Twice per day',
    frequency_1_time_per_day: 'Daily',
    frequency_every_2_days: 'Every two days',
    frequency_every_3_days: 'Every three days',
    frequency_twice_per_week: 'Twice per week',
    frequency_once_per_week: 'Every week',
    frequency_every_other_week: 'Every other week',
    frequency_every_month: 'Every month',
    frequency_other: 'Other'
  }

  enum therapy_quantity: {
    quantity_0_5: '0.5',
    quantity_1: '1',
    quantity_2: '2',
    quantity_3: '3',
    quantity_4: '4',
    quantity_other: 'Other'
  }

  attr_readonly :patient_therapy_id, :patient_id, :create_user, :create_date
  # attr_accessible :start_date, :end_date, :health_event_duration, :record_order, :therapy, :therapy_frequency,
  #   :therapy_quantity, :therapy_strength_form, :privacy,
  #   :imo_code, :icd9_code, :icd10_code, :health_event_scope,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id, :health_event_scope,
  #   :as => :admin

  if self.respond_to?(:set_date_columns)
    set_date_columns :start_date, :end_date
  end

  def strength_dose(for_paramedic)
    strength = self[:therapy_strength_form]
    frequency = as_json_frequency
    quantity = as_json_quantity
    str_build = []

    if strength.present? and strength.downcase != 'other'
      str_build << strength.downcase
    end
    
    if quantity.present? and quantity.downcase != 'other'
      str_build << "x#{quantity}"
    end
    
    if frequency.present? and frequency.downcase != 'other'
      if for_paramedic and frequency.downcase == 'as needed'
        str_build << 'p.r.n.'
      else
        str_build << frequency.downcase
      end
    end

    str_build.join(', ')
  end

  # Table relationships

  belongs_to :patient, :inverse_of => :patient_therapies

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 
  has_many :strength_forms, :class_name => 'ImoMedNameStrengthForm', :foreign_key => :med_name, :primary_key => :therapy
  has_many :generics, :class_name => 'ImoMedGenericName', :foreign_key => :med_name, :primary_key => :therapy

  # Validations
  
  validates :therapy, :length => {:maximum => 300}, :presence => true
  validates :therapy_strength_form, :length => {:maximum => 1000}
  validates :therapy_frequency, :length => {:maximum => 100}
  validates :therapy_quantity, :length => {:maximum => 100}
  validates_date :start_date, :allow_nil => true, :allow_blank => true
  validates_date :end_date, :allow_nil => true, :allow_blank => true

  # API precomputed title/description for common consumption
  def title
    self.therapy
  end

  def description
    tA = []
    tA.append(self[:therapy_strength_form]) if self.therapy_strength_form.present?
    tA.append(as_json_quantity) if self.therapy_quantity.present?
    tA.append(as_json_frequency) if self.therapy_frequency.present?
    tA.join(", ")
  end

  def as_json_frequency
    self.therapy_frequency.present? ? PatientTherapy.therapy_frequencies[self.therapy_frequency] : ""
  end

  def as_json_quantity
    self.therapy_quantity.present? ? PatientTherapy.therapy_quantities[self.therapy_quantity] : ""
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description, :alert => is_flagged,
      :therapy_quantity => as_json_quantity, :therapy_frequency => as_json_frequency })
  end

  # GHETTO TOWN USA ON ALERTS

  # TODO: no longer valid though? maybe a new API or something
  ALERT_CODES = [
    '129822', #Warfarin
    '112934' #Coumadin
  ]

  def is_flagged
    if imo_code != nil
      ALERT_CODES.each do |alert_code|
        if imo_code.to_s == alert_code.to_s
          return true
        end
      end
    end
    return false
  end

  POPULAR_ITEMS = [
    
    # {
    #   :name => 'Pain Killers',
    #   :items => [
    #     {
    #       :title => 'Tylenol',
    #       :code => 144372
    #     },
    #     {
    #       :title => 'Ibuprofen',
    #       :code => 116076
    #     },
    #     {
    #       :title => 'Aleve',
    #       :code => 200630
    #     },
    #     {
    #       :title => 'Aspirin',
    #       :code => 125475
    #     }
    #   ]
    # },
    # {
    #   :name => 'Another Category',
    #   :items => [
    #     {
    #       :title => 'Tylenol',
    #       :code => 144372
    #     },
    #     {
    #       :title => 'Ibuprofen',
    #       :code => 116076
    #     },
    #     {
    #       :title => 'Aleve',
    #       :code => 200630
    #     },
    #     {
    #       :title => 'Aspirin',
    #       :code => 125475
    #     }
    #   ]
    # },
    # {
    #   :name => 'Last Category',
    #   :items => [
    #     {
    #       :title => 'Tylenol',
    #       :code => 144372
    #     },
    #     {
    #       :title => 'Ibuprofen',
    #       :code => 116076
    #     },
    #     {
    #       :title => 'Aleve',
    #       :code => 200630
    #     },
    #     {
    #       :title => 'Aspirin',
    #       :code => 125475
    #     }
    #   ]
    # },
  ]

end
