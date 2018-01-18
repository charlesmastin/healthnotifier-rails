class PatientNetwork < ApplicationRecord
  self.primary_keys = [:granter_patient_id, :auditor_patient_id]
  belongs_to :granter_patient, -> { readonly }, class_name: :Patient, inverse_of: :network_auditors, touch: true
  belongs_to :auditor_patient, -> { readonly }, class_name: :Patient, inverse_of: :network_granters, touch: true

  def as_json(options = { })
    # we need the name, and healthcare provider status of each relationship, just for giggle
    # will this bomb on an defunt relationship, probably, so protect this house somehow

    super(options).merge({
        :granter_uuid => self.granter_patient.uuid,
        # TODO: remove this in the controllers, we only need it for select Android client versions
        :granter_lifesquare => (self.granter_patient.lifesquare ? self.granter_patient.lifesquare.lifesquare_uid : ''), # this is a temporary Android only fix… ugg
        :granter_name => self.granter_patient.name_extended,
        :granter_photo_uuid => self.granter_patient.photo_uid,
        :granter_provider => self.granter_patient.account.provider?,
        :auditor_uuid => self.auditor_patient.uuid,
        :auditor_name => self.auditor_patient.name_extended,
        :auditor_photo_uuid => self.auditor_patient.photo_uid,
        :auditor_provider => self.auditor_patient.account.provider?,
        :title => '', # TODO
        :description => '' # TODO
    })
  end

end

# TODO: move back those static methods when better at ruby