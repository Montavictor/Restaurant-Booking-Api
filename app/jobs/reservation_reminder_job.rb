class ReservationReminderJob < ApplicationJob
  queue_as :default
  
  def perform(reservation_id)
    reservation = ReservationInfo.find_by(id: reservation_id)
    return unless reservation&.confirmed?
    
    ReservationMailer.reminder_email(reservation).deliver_now
  rescue => e
    Rails.logger.error "Reminder email failed for reservation #{reservation_id}: #{e.message}"
  end
end

class WebhookRetryJob < ApplicationJob
  queue_as :webhooks
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(event_id, event_type, event_data)
    # Check if already processed
    return if WebhookTracker.processed?(event_id)
    
    # Mark as processing to prevent concurrent execution
    WebhookTracker.mark_processing(event_id)
    
    begin
      case event_type
      when "payment_intent.succeeded"
        handle_payment_intent_succeeded(event_data['object'])
      when "charge.refunded"
        handle_charge_refunded(event_data['object'])
      end
      
      WebhookTracker.mark_processed(event_id)
      Rails.logger.info "Successfully retried webhook event #{event_id}"
      
    rescue => e
      Rails.logger.error "Webhook retry failed for event #{event_id}: #{e.message}"
      raise e # This will trigger the retry mechanism
    ensure
      WebhookTracker.clear_processing(event_id)
    end
  end
  
  private
  
  def handle_payment_intent_succeeded(payment_intent_data)
    return if ReservationInfo.exists?(stripe_id: payment_intent_data['id'])
    
    payment_service = PaymentService.new({})
    result = payment_service.confirm_payment(payment_intent_data['id'])
    
    unless result[:success]
      raise "Failed to create reservation: #{result[:error]}"
    end
    
    reservation = ReservationInfo.find(result[:reservation_id])
    reservation.update_column(:webhook_processed_at, Time.current)
    ReservationMailer.confirmation_email(reservation).deliver_later
  end
  
  def handle_charge_refunded(charge_data)
    reservation = ReservationInfo.find_by(stripe_id: charge_data['payment_intent'])
    return unless reservation
    
    reservation.cancel_reservation! unless reservation.cancelled?
    ReservationMailer.cancellation_email(reservation).deliver_later
  end
end