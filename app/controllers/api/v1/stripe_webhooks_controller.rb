class Api::V1::StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  
  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "Webhook JSON parse error: #{e.message}"
      return render json: { error: "Invalid payload" }, status: 400
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook signature verification failed: #{e.message}"
      return render json: { error: "Invalid signature" }, status: 400
    end
    
    # Check if we've already processed this event
    if WebhookTracker.processed?(event.id)
      Rails.logger.info "Webhook event #{event.id} already processed"
      return head :ok
    end
    
    # Check if we're currently processing this event (prevent concurrent processing)
    if WebhookTracker.processing?(event.id)
      Rails.logger.info "Webhook event #{event.id} is currently being processed"
      return head :ok
    end
    
    # Mark as processing
    WebhookTracker.mark_processing(event.id)
    
    begin
      case event.type
      when "payment_intent.succeeded"
        handle_payment_intent_succeeded(event.data.object)
      when "charge.dispute.created"
        handle_charge_dispute_created(event.data.object)
      else
        Rails.logger.info "Unhandled webhook event type: #{event.type}"
      end
      
      # Mark as processed
      WebhookTracker.mark_processed(event.id)
      Rails.logger.info "Successfully processed webhook event #{event.id}"
      
    rescue => e
      Rails.logger.error "Webhook processing failed for event #{event.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      
      # Clear processing flag so it can be retried
      WebhookTracker.clear_processing(event.id)
      
      # For critical errors, you might want to queue a retry job
      if should_retry_webhook?(event.type)
        WebhookRetryJob.perform_later(event.id, event.type, event.data.to_hash)
      end
      
      # Still return 200 to prevent Stripe retries for most application errors
      # Only return error status for truly unrecoverable errors
    ensure
      WebhookTracker.clear_processing(event.id)
    end
    
    head :ok
  end
  
  private
  
  def handle_payment_intent_succeeded(payment_intent)
    # Check if reservation already exists (idempotency)
    existing_reservation = ReservationInfo.find_by(stripe_id: payment_intent.id)
    if existing_reservation
      # Update webhook_processed_at if not already set
      unless existing_reservation.webhook_processed_at
        existing_reservation.update_column(:webhook_processed_at, Time.current)
      end
      Rails.logger.info "Reservation #{existing_reservation.id} already exists for payment intent #{payment_intent.id}"
      return
    end
    
    payment_service = PaymentService.new({})
    result = payment_service.confirm_payment(payment_intent.id)
    
    if result[:success]
      reservation = ReservationInfo.find(result[:reservation_id])
      reservation.update_column(:webhook_processed_at, Time.current)
      
      Rails.logger.info "Reservation #{reservation.id} created via webhook for payment intent #{payment_intent.id}"
    else
      Rails.logger.error "Failed to create reservation from webhook: #{result[:error]}"
      raise "Failed to create reservation: #{result[:error]}"
    end
  end
  
  def handle_charge_dispute_created(dispute)
    reservation = ReservationInfo.find_by(stripe_id: dispute.payment_intent)
    return unless reservation
    
    # Update reservation status
    reservation.update!(status: "disputed")
    
    # Notify admin
    AdminMailer.dispute_notification(reservation, dispute).deliver_later
    
    Rails.logger.warn "Dispute created for reservation #{reservation.id}"
  end
  
  def should_retry_webhook?(event_type)
    # Only retry critical events
    %w[payment_intent.succeeded charge.refunded].include?(event_type)
  end
end