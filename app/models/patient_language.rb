class PatientLanguage < ApplicationRecord
  self.sequence_name = :seq_patient_language

  enum language_proficiency: {
    native: 'NATIVE',
    fluent: 'FLUENT',
    secondary: 'SECONDARY'
  }

  attr_readonly :patient_language_id, :patient_id, :create_user, :create_date
  # attr_accessible :language_code, :language_proficiency, :record_order, :as => [:admin,:default]
  # attr_accessible :patient_id, :as => :admin

  # Table relationships
  belongs_to :patient, :inverse_of => :patient_languages

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id 

  # Validations

  validates_uniqueness_of :language_code, :scope => :patient_id, :message => 'Duplicate entry for language'

  before_create do
    create_date = DateTime.now
  end

  # json nutters
  def as_json_language_proficiency
    PatientLanguage.language_proficiencies[self.language_proficiency]
  end

  def title
    languageCodes = Values.call('language_code')
    languageCodes.each do |obj|
      if obj[:value] == self.language_code
        return obj[:name]
      end
    end
  end

  def description
    (as_json_language_proficiency || '').titleize
  end

  def as_json(options = { })
    super(options).merge({:title => title, :description => description, :language_proficiency => as_json_language_proficiency })
  end

end
