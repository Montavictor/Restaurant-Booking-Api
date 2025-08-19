require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = {url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")}
  
  # load cron jobs on server start
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash!(YAML.load_file("config/cron.yml"))
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")}
end
