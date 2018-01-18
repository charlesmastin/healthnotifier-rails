twilio_credentials = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['twilio']

Rails.configuration.twilio = {
  :phone_number => twilio_credentials['phone_number'],
  :account_sid => twilio_credentials['account_sid'],
  :auth_token => twilio_credentials['auth_token'],
}
