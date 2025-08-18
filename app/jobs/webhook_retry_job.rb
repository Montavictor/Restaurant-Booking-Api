# app/jobs/webhook_retry_job.rb
class WebhookRetryJob < ApplicationJob
  queue_as :default

  # event_payload is the raw data from Stripe (hash)
  def perform(event_id, event_type, event_payload)
    Rails.logger.info "Retrying webhook #{event_id} of type #{event_type}"

    case event_type
    when "payment_intent.succeeded"
      Api::V1::StripeWebhooksController.new.send(:handle_payment_intent_succeeded, OpenStruct.new(event_payload["object"]))
    when "charge.dispute.created"
      Api::V1::StripeWebhooksController.new.send(:handle_charge_dispute_created, OpenStruct.new(event_payload["object"]))
    else
      Rails.logger.info "Unhandled webhook retry type: #{event_type}"
    end
  rescue => e
    Rails.logger.error "WebhookRetryJob failed for event #{event_id}: #{e.message}"
    raise e # let Sidekiq retry again with exponential backoff
  end
end
