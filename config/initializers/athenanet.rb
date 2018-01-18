athenanet_credentials = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['athenanet']

Rails.configuration.athenanet = {
  :base_url => 'https://api.athenahealth.com',
  :key => athenanet_credentials['key'],
  :secret => athenanet_credentials['secret']
}
