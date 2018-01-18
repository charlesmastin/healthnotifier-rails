class PatientHealthAttribute < ApplicationRecord
  include PrivacyValidations
  self.sequence_name = :patient_health_attribute_patient_health_attribute_id_seq

  attr_readonly :patient_health_attribute_id, :patient_id, :create_user, :create_date
  # attr_accessible :value, :start_date, :end_date, :record_order, :privacy,
  #   :as => [:admin, :default]
  # attr_accessible :patient_id,
  #   :as => :admin

  if self.respond_to?(:set_date_columns)
    set_date_columns :start_date, :end_date
  end

  # Table relationships
  belongs_to :patient, :inverse_of => :patient_health_attributes
  belongs_to :document_digitized

  has_many :account_patients, :foreign_key => :patient_id, :primary_key => :patient_id

  # For rails_admin
  def name
    self.patient_health_attribute_id
  end

  # PLEASE SAVE ME FROM THIS!
  def self.directives_by_patient_id(patient_id)
    where(%{patient_id = ?}, patient_id)
  end

  # Validations
  validates :value, :length => {:maximum => 1024}
  validates_date :start_date, :allow_nil => true, :allow_blank => true
  validates_date :end_date, :allow_nil => true, :allow_blank => true

  # API precomputed title/description for common consumption
  
  # def title
  #   self.therapy
  # end

  # TODO: MOVE MOVE MOVE MOVE MOVE MOVE MOVE MOVE MOVE TO SOME DRY GROUND SON
  def self.humanize_dd_category(category)
    Values.call('document').concat(Values.call('directive')).each do |cat|
      if category == cat[:value]
        return cat[:name]
      end
    end
    category
  end

  # def description
  #   "#{self[:therapy_strength_form]}, #{self[:therapy_quantity]}, #{self[:therapy_frequency]}"
  # end
  # humanize_dd_category

  # because this is in use for all the things, FREEEFORM FREEBALLS, it will fails

  def as_json(options = { })
    # meh, try to decorate only if we're a FREEFORM SON, jk if we're a DD JW
    if self.document_digitized != nil
      category = PatientHealthAttribute.humanize_dd_category(self.document_digitized.category)
      pages = self.document_digitized.document_digitized_files.count
      begin
        thumbnail_uuid = self.document_digitized.document_digitized_files[0].uid
        # this is donkey balls because we don't have access to the request at this point, and we can't supply the specific protocol and port
        thumbnail_url = Rails.application.routes.url_helpers.api_file_retrieve_url(thumbnail_uuid)
      rescue
        thumbnail_uuid = nil
        thumbnail_url = nil
      end
      super(options).merge({
        :title => self.document_digitized.title, # DICK FACE
        :description => (pages > 1 ) ? "#{pages} Pages": "#{pages} Page",
        :uuid => self.document_digitized.uid,
        :category => self.document_digitized.category,
        # thhis should be a raw thing self.document_digitized.category
        # apps should use Values API, lolzone
        :pages => pages,
        :thumbnail_uuid => thumbnail_uuid,
        :thumbnail_url => thumbnail_url
      })
    end
  end

end
