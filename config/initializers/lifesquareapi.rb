lifesquareapi_credentials = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['lifesquareapi']

Rails.configuration.lifesquareapi = {
  :hmac_secret => lifesquareapi_credentials['hmac_secret']
}
