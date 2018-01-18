stripe_creds = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['stripe']

# condition based on ENV SON, this is kinda important so I can test my own cards without doing chargebacks / refunds
# TODO: adjust so we can also use testing keys on beta / staging
Rails.configuration.stripe = {
  :publishable_key => Rails.env.production? ? stripe_creds['live_publishable_key'] : stripe_creds['test_publishable_key'],
  :secret_key      => Rails.env.production? ? stripe_creds['live_secret_key'] : stripe_creds['test_secret_key'],
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]