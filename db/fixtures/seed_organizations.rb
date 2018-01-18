if ['development', 'test'].include? Rails.env
    Organization.seed(
            {name: 'HealthNotifier',   contact_last_name: 'Last', contact_first_name: 'First', contact_salutation: 'Ms.', contact_title: '',        contact_email: 'email@domain.com',       contact_phone: '415-420-6969'}
            )
end # if ... Rails.env