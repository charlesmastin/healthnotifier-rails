class PatientHealthEvent < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_phe

  # TODO: if we need, have the formatted versions for display?
  enum health_event_type: {
    condition: 'CONDITION',
    procedure: 'PROCEDURE',
    immunization: 'IMMUNIZATION'
  }
  # health_event_duration is not used in production,???
  # TODO: shared enum with patient_therapy DRY UP LOL
  enum health_event_duration: {
    duration_1week: '1WEEK',
    duration_1month: '1MONTH',
    duration_3month: '3MONTH',
    duration_6month: '6month',
    duration_9month: '9month',
    duration_1year: '1YEAR',
    duration_2year: '2YEAR',
    duration_5year: '5YEAR',
    duration_10year: '10YEAR',
    duration_indefinite: 'INDEFINITE'
  }

  # TODO: shared enum with patient_therapy DRY UP LOL
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
  

  alias_attribute :name, :health_event

  attr_readonly :patient_health_event_id, :patient_id, :create_user, :create_date
  # attr_accessible :start_date, :end_date, :health_event_duration, :record_order, :health_event,
  #   :health_event_type, :start_date_mask, :privacy,
  #   :imo_code, :icd9_code, :icd10_code, :health_event_scope,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id, :health_event_scope,
  #   :as => :admin

  if self.respond_to?(:set_date_columns)
    set_date_columns :start_date, :end_date
  end

  # TODO: use the enum accessors instead of the raw string values? ehh?
  def self.conditions_by_patient_id(patient_id)
    where(%{patient_id = ? AND health_event_type = 'CONDITION'}, patient_id)
  end

  def self.devices_by_patient_id(patient_id)
    where(%{patient_id = ? AND health_event_type = 'DEVICE'}, patient_id)
  end

  def self.immunizations_by_patient_id(patient_id)
    where(%{patient_id = ? AND health_event_type = 'IMMUNIZATION'}, patient_id).reorder('health_event')
  end

  def self.procedures_by_patient_id(patient_id)
    where(%{patient_id = ? AND health_event_type = 'PROCEDURE'}, patient_id)
  end

  def expected_end_date
    return nil unless self[:health_event_duration]
    if self[:health_event_duration] == '1WEEK'
      return self[:start_date] + 7
    elsif self[:health_event_duration] == '1MONTH'
      return self[:start_date] + 31
    elsif self[:health_event_duration] == '3MONTH'
      return self[:start_date] + 93
    elsif self[:health_event_duration] == '6MONTH'
      return self[:start_date] + 183
    elsif self[:health_event_duration] == '9MONTH'
      return self[:start_date] + 275
    elsif self[:health_event_duration] == '1YEAR'
      return self[:start_date] + 366
    elsif self[:health_event_duration] == '2YEAR'
      return self[:start_date] + 731
    elsif self[:health_event_duration] == '5YEAR'
      return self[:start_date] + 1826
    elsif self[:health_event_duration] == '10YEAR'
      return self[:start_date] + 3652
    elsif self[:health_event_duration] == 'INDEFINITE'
      return 'Indefinite'
    else
      Rails.logger.error("Unknown health_event_duration: #{self[:health_event_duration]}")
    end

    return nil
  end

  # Table relationships

  #belongs_to :icd9_lexicals_text_imo, :foreign_key => :health_event, :primary_key => :imo_lc_text

  belongs_to :patient, :inverse_of => :patient_health_events
  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations
  
  validates_date :start_date, :allow_nil => true, :allow_blank => true
  validates_date :end_date, :allow_nil => true, :allow_blank => true

  validates :health_event, :length => {:maximum => 300}, :presence => true

##at example is: after_find :eager_load, 'self.class.announce(#{id})' ??

  # API precomputed title/description for common consumption
  def title
    self.health_event
  end

  def description
    # TODO split on type and customize further
    begin
      "#{self.start_date.strftime('%m/%d/%Y')}"
    rescue
      ""
    end
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description})
  end

  # TODO: code up

  # TODO: popular conditions
  CONDITION_POPULAR_ITEMS = [
    {
      :name => 'Common Conditions',
      :items => [
        {
          :title => 'Acute arthiritis',
          :code => 1335
        },
        {
          :title => 'Heart disease',
          :code => 45645
        },
        {
          :title => 'Cancer',
          :code => 36262
        },
        {
          :title => 'Respitory disease',
          :code => 939777
        },
        {
          :title => 'Alzheimer\'s disease',
          :code => 37864
        },
        # {
        #   :title => 'Osteoperosis',
        #   :code => 144372
        # },
        {
          :title => 'Diabetes',
          :code => 41884
        },
        {
          :title => 'Influenza',
          :code => 86569
        },
        {
          :title => 'Pneumonia',
          :code => 87580
        },
      ]
    }
  ]

  # TODO: popular devices
  DEVICE_POPULAR_ITEMS = [

    # {
    #   :name => 'Common Devices',
    #   :items => [
    #     {
    #       :title => 'Pacemaker',
    #       :code => 300740
    #     },

    #     {
    #       :title => 'Replacement Hip',
    #       :code => 144372
    #     },
    #     {
    #       :title => 'Artificial Limb',
    #       :code => 144372
    #     },
    #     {
    #       :title => 'AI Brain',
    #       :code => 144372
    #     },
    #   ]
    # }
  ]

  # TODO: add correct codes
  IMMUNIZATION_POPULAR_ITEMS = [
    {
      :name => 'Common Vaccines',
      :items => [
        {
          :title => 'Polio',
          :code => 300801
        },
        {
          :title => 'Immunization, DTP/DTaP',
          :code => 813478
        },
        # TODO: this is conditional based on being up to date, etc, aka interplay with date administered, uggg
        {
          :title => 'Measels, Mumps, Rubella (MMR)',
          :code => 40827345
        },
        {
          :title => 'Varicella vaccination',
          :code => 1524958
        },
        {
          :title => 'Hepatitis B',
          :code => 300467
        },
        #
        #{
        #  :title => 'Pneumococcal (PCV13)',
        #  :code => 125475
        #}
      ]
    },
  ]

end
