Replicate.client.api_token = ENV.fetch('REPLICATE_TOKEN')

class ReplicateWebhook
  def call(prediction)
    # do your thing
  end
end

ReplicateRails.configure do |config|
  config.webhook_adapter = ReplicateWebhook.new
end