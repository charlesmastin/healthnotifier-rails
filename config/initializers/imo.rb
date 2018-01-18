imo_credentials = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['imo']

Rails.configuration.imo = {
  :base_url => 'https://api.athenahealth.com',
  :access_id => imo_credentials['access_id'],
}
