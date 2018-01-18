if ['development', 'test'].include? Rails.env
  email_domain_application = 'domain.com'
  AdminUser.seed(
    :email,
    {email: "admindev@#{email_domain_application}", password: 'admindev2014Pass'}
  )
  email_domain_devtest = ENV['RAILS_EMAIL_DOMAIN_DEVTEST'] || email_domain_application
  accounts = Account.seed(
    :email,
    {email: "devtestls1@#{email_domain_devtest}", password: 'devtestls1Pass', confirmed_at: '2014-05-01 12:00:00', account_type: 'PROVIDER'},
    {email: "devtestls2@#{email_domain_devtest}", password: 'devtestls2Pass', confirmed_at: '2014-05-01 12:00:00'},
    {email: "devtestls3@#{email_domain_devtest}", password: 'devtestls3Pass', confirmed_at: '2014-05-01 12:00:00'}
  )
  account1 = accounts[0]
  account2 = accounts[1]
  account3 = accounts[2]
  patients = Patient.seed(
    :account_id, :create_user, :first_name, :last_name,
    {account_id:                account1.id,
     create_user:               account1.id,
     update_user:               account1.id,
     first_name:                'Janet',
     middle_name:               'Doe',
     last_name:                 'Providence',
     birthdate:                 '1981-01-01',
     gender:                    'F',
     ethnicity:                 'BLACK',
     hair_color:                'Black',
     eye_color_both:            'Black',
     height:                    154.94,
     weight:                    68.49244787,
     medication_presence:       '0',
     allergy_presence:          '0',
     condition_presence:        '0',
     procedure_presence:        '0',
     directive_presence:        '0',
     confirmed:                 1},
    {account_id:                account2.id,
     create_user:               account2.id,
     update_user:               account2.id,
     first_name:                'Bob',
     middle_name:               'Lacks',
     last_name:                 'Patience',
     birthdate:                 '1972-02-02',
     gender:                    'M',
     ethnicity:                 'WHITE',
     hair_color:                'Blond',
     eye_color_both:            'Blue',
     height:                    187.96,
     weight:                    92.98643585,
     medication_presence:       '0',
     allergy_presence:          '0',
     condition_presence:        '0',
     procedure_presence:        '0',
     directive_presence:        '1',
     confirmed:                 1},
    {account_id:                account2.id,
     create_user:               account2.id,
     update_user:               account2.id,
     first_name:                'Cindy',
     middle_name:               'Has',
     last_name:                 'Patience',
     birthdate:                 '1963-03-03',
     gender:                    'F',
     ethnicity:                 'ASIAN',
     hair_color:                'Black',
     eye_color_both:            'Black',
     height:                    154.94,
     weight:                    68.49244787,
     medication_presence:       '0',
     allergy_presence:          '0',
     condition_presence:        '0',
     procedure_presence:        '0',
     directive_presence:        '1',
     confirmed:                 1,
     searchable:                false}
  )
  patient1  = patients[0]
  patient2a = patients[1]
  patient2b = patients[2]
  
  PatientNetwork.seed(
    :granter_patient_id,               :auditor_patient_id,
    ## !!! using _id instead of association is necessary to prevent duplication
    #{granter_patient: patient1,         auditor_patient: patient2a},
    #{granter_patient: patient1,         auditor_patient: patient2b},
    #{granter_patient: patient2a,        auditor_patient: patient1},
    #{granter_patient: patient2b,        auditor_patient: patient2a}
    {granter_patient_id: patient1.id,   auditor_patient_id: patient2a.id, asked_at: '2017-04-20 12:00:00'},
    {granter_patient_id: patient1.id,   auditor_patient_id: patient2b.id, asked_at: '2017-04-20 12:00:00'},
    {granter_patient_id: patient2a.id,  auditor_patient_id: patient1.id,  privacy: 'provider', asked_at: '2017-04-20 12:00:00'},
    {granter_patient_id: patient2b.id,  auditor_patient_id: patient2a.id, privacy: 'private', auditor_is_family: true, auditor_has_power_of_attorney: true, asked_at: '2017-04-20 12:00:00'}
  )
  PatientResidence.seed(
    :patient_id, :address_line1, :residence_type,
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient1,
    {patient_id:                patient1.id,
     create_user:               account1.id,
     update_user:               account1.id,
     address_line1:             '1 Hallidie Plaza',
     address_line2:             '2nd Floor',
     city:                      'San Francisco',
     state_province:            'CA',
     postal_code:               '94102',
     residence_type:            'WORK',
     lifesquare_location_type:  'Other',
     lifesquare_location_other: 'BART Powell station'},
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient2a,
    {patient_id:                patient2a.id,
     create_user:               account2.id,
     update_user:               account2.id,
     address_line1:             '11 Jewel Ct.',
     city:                      'Orinda',
     state_province:            'CA',
     postal_code:               '94563',
     residence_type:            'WORK',
     lifesquare_location_type:  'Wallet',
     },
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient2b,
    {patient_id:                patient2b.id,
     create_user:               account2.id,
     update_user:               account2.id,
     address_line1:             '615 Healdsburg Ave.',
     address_line2:             '#303',
     city:                      'Santa Rosa',
     state_province:            'CA',
     postal_code:               '95401',
     residence_type:            'HOME',
     lifesquare_location_type:  'Home Phone'
     }
  ).each {|pr| pr.save}
  Lifesquare.seed(
    :lifesquare_uid,
    {lifesquare_uid:            '223UQ56GS',
     create_user:               account1.id,
     update_user:               account1.id,
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient1,
     patient_id:                patient1.id,
     valid_state:               1},
=begin
  # !!! need to test not yet having lifesquares for a patient
    {lifesquare_uid:            '224QH2DK7',
     create_user:               account2.id,
     update_user:               account2.id,
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient2a,
     patient_id:                patient2a.id,
     valid_state:               1},
=end
    {lifesquare_uid:            '226C2LV6A',
     create_user:               account2.id,
     update_user:               account2.id,
    ## !!! using _id instead of association is necessary to prevent duplication
    ##{patient:                   patient2b,
     patient_id:                patient2b.id,
     valid_state:               1},
  )
end # if ... Rails.env
