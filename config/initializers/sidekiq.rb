sidekiq_creds = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['sidekiq']

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_creds['redis']['url'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_creds['redis']['url'] }
end

Sidekiq.configure_server do |config|
  # default is 15 or processes * 5
  config.average_scheduled_poll_interval = 5
end