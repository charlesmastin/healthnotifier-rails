class Values
  def self.call(model, attribute=nil)
    # this is really like an all models service or something by itself, since it glues things togetehr in common output and meshes various input formats

    # this is a fake model, but richer than the original definition chucked in application.rb
    if model == 'privacy' && attribute == nil
      # weight is(will be) used to determine the permissive stack
      # currently the definition order and the bla.index is what is evaluated
      return [
          {
            :value => 'public',
            :name => 'HealthNotifier Network',
            :icon => 'people',
            :short_description => 'Visible to registered users who scan your LifeSticker.',
            :weight => 0
          },
          {
            :value => 'provider',
            :name => 'Authorized Viewers',
            :icon => 'verified_user',
            :short_description => 'Visible to verified health care providers or select users you authorize.',
            :weight => 1
          },
          {
            :value => 'private',
            :name => 'Private',
            :icon => 'lock',
            :short_description => 'Visible only to you.',
            :weight => 2
          }
      ]
    end

    # TODO: Move this to a enum on the DD model
    if model == 'directive' && attribute == nil
      return [
          {
            :value => 'POLST',
            :name => 'POLST Form'
          },
          {
            :value => 'DNR',
            :name => 'DNR'
          },
          {
            :value => 'ADVANCE_DIRECTIVE',
            :name => 'Advance Directive'
          }
      ]
    end

    # TODO: Move this to a enum on the DD model
    if model == 'document' && attribute == nil
      return [
          {
            :value => 'IMAGING_RESULT',
            :name => 'Imaging Result'
          },
          {
            :value => 'LAB_RESULT',
            :name => 'Lab Result'
          },
          {
            :value => 'ECG',
            :name => 'ECG'
          },
          {
            :value => 'MEDICAL_NOTE',
            :name => 'Medical Note'
          }
      ]
    end

    # this is for US states yo, we need some hacking here to get listings for a few countries,
    # but honestly, we should use a gem for this
    if model == 'state'
      return States.call.map { |v, k| {:value => v, :name => k} }
    end

    if model == 'country'
      return Countries.call.map { |v, k| {:value => k, :name => v} }
    end
    
    # actual enums or model collections now
    if model == 'patient' && attribute == 'gender'
      return Patient.genders.map { |v, k| {:value => k, :name => v.titleize} }
    end

    if model == 'patient' && attribute == 'ethnicity'
      return Patient.formatted_ethnicities.map { |v, k| {:value => v, :name => k} }
    end

    if model == 'patient' && attribute == 'hair_color'
      return Patient.hair_colors.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'patient' && attribute == 'eye_color'
      return Patient.eye_colors.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'patient' && attribute == 'blood_type'
      return Patient.blood_types.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'language_code' && attribute == nil
      return Languages.call.map { |v, k| {:value => v, :name => k} } # this one is flip-flopped
    end

    if model == 'patient_language' && attribute == 'proficiency'
      return PatientLanguage.language_proficiencies.map { |v, k| {:value => k, :name => k.titleize } }
    end

    if model == 'patient_residence' && attribute == 'residence_type'
      return PatientResidence.formatted_residence_types.map { |v, k| {:value => v, :name => k} }
    end

    if model == 'patient_residence' && attribute == 'lifesquare_location_type'
      return PatientResidence.lifesquare_location_types.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'patient_allergy' && attribute == 'reaction'
      return PatientAllergy.reactions.map { |v, k| {:value => k, :name => k} }
    end
    
    if model == 'patient_therapy' && attribute == 'therapy_frequency'
      return PatientTherapy.therapy_frequencies.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'patient_therapy' && attribute == 'therapy_quantity'
      return PatientTherapy.therapy_quantities.map { |v, k| {:value => k, :name => k} }
    end

    if model == 'patient_contact' && attribute == 'relationship'
      return PatientContact.formatted_contact_relationships.map { |v, k| {:value => v, :name => k} }
    end

    if model == 'patient_care_provider' && attribute == 'care_provider_class'
      return PatientCareProvider.formatted_care_provider_classes.map { |v, k| {:value => v, :name => k} }
    end
  end
end