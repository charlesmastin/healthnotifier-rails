pingone_credentials = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['pingone']

Rails.configuration.pingone = {
  :token_service_base_url => 'https://sso.connect.pingidentity.com',
  :rest_api_client_id => pingone_credentials['rest_api_client_id'],
  :rest_api_client_secret => pingone_credentials['rest_api_client_secret']
}
