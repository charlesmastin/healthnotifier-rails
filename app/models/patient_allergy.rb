class PatientAllergy < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :seq_patient_allergy

  alias_attribute :name, :allergen

  attr_readonly :patient_allergy_id, :patient_id, :create_user, :create_date
  # attr_accessible :start_date, :end_date, :record_order, :allergen, :allergy_cause_notes, :reaction, :privacy,
  #   :imo_code, :icd9_code, :icd10_code, :health_event_scope,
  #   :as => [:admin,:default]
  # attr_accessible :patient_id, :health_event_scope,
  #   :as => :admin

  if self.respond_to?(:set_date_columns)
    set_date_columns :start_date, :end_date
  end

  enum reaction: {
    reaction_anaphylaxis: 'Anaphylaxis',
    reaction_diarrhea: 'Diarrhea',
    reaction_hives: 'Hives',
    reaction_itching: 'Itching',
    reaction_nausea: 'Nausea',
    reaction_rash: 'Rash',
    reaction_shortness_of_breath: 'Shortness of Breath',
    reaction_swelling: 'Swelling',
    reaction_vomiting: 'Vomiting',
    quantity_other: 'Other'
  }

  def as_json_reaction
    self.reaction.present? ? PatientAllergy.reactions[self.reaction] : ""
  end

  # Table relationships

  belongs_to :patient, :inverse_of => :patient_allergies

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations
  
  validates_date :start_date, :allow_nil => true, :allow_blank => true
  validates_date :end_date, :allow_nil => true, :allow_blank => true

  validates :allergen, :length => {:maximum => 300}, :presence => true
  validates :reaction, :length => {:maximum => 300}
  validates :allergy_cause_notes, :length => {:maximum => 2000}

  # API precomputed title/description for common consumption
  def title
    self.allergen
  end

  def description
    as_json_reaction
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description, :reaction => as_json_reaction})
  end

  POPULAR_ITEMS = [
    {
      :name => 'Common Allergies',
      :items => [
        {
          :title => 'Pollen allergy',
          :code => 937440
        },
        {
          :title => 'House dust mite allergy',
          :code => 709953
        },
        {
          :title => 'Allergy to mold',
          :code => 50988115
        },
        {
          :title => 'Animal dander allergy',
          :code => 3030
        },
        {
          :title => 'Insect Sting',
          :code => 57317
        },
        {
          :title => 'Latex allergy',
          :code => 845816
        }
      ]
    },
    {
      :name => 'Food Allergies',
      :items => [
        {
          :title => 'Dairy allergy',
          :code => 706244
        },
        {
          :title => 'Peanut allergy',
          :code => 386468
        },
        {
          :title => 'Soy allergy',
          :code => 1669729
        },
        {
          :title => 'Shellfish allergy',
          :code => 300894
        }
      ]
    },
    {
      :name => 'Drug Allergies',
      :items => [
        {
          :title => 'Penicillin allergy',
          :code => 807238
        },
        {
          :title => 'Sulfa sensitivity',
          :code => 1049085
        },
        # Anticonvulsants
        {
          :title => 'Aspirin allergy',
          :code => 709652
        },
        # chemo
      ]
    },

  ]


end
