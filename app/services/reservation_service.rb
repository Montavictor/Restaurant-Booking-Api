class ReservationService
  def self.create_reservation(params)
    payment_service = PaymentService.new(params)
    payment_service.create_payment_intent
  end
  
  def self.confirm_reservation(payment_intent_id)
    payment_service = PaymentService.new({})
    payment_service.confirm_payment(payment_intent_id)
  end
  
  def self.cancel_reservation(cancellation_token)
    reservation = ReservationInfo.find_by(cancellation_token: cancellation_token)
    return { error: "Reservation not found" } unless reservation
    
    return { error: "Reservation already cancelled" } if reservation.cancelled?
    
    unless reservation.can_be_cancelled?
      return { 
        error: "Cannot cancel within #{ReservationInfo::CANCEL_WINDOW_DAYS} days",
        last_cancellation_date: (reservation.reservation_date - ReservationInfo::CANCEL_WINDOW_DAYS.days)
      }
    end
    
    begin
      ActiveRecord::Base.transaction do
        reservation.cancel_reservation!
        refund_result = RefundService.new(reservation).process_refund
        
        # Send cancellation email
        ReservationMailer.cancellation_email(reservation).deliver_later
        
        {
          success: true,
          reservation_id: reservation.id,
          refund_processed: refund_result[:success]
        }
      end
    rescue => e
      Rails.logger.error "Cancellation service error: #{e.message}"
      { error: "Cancellation failed" }
    end
  end
  
  def self.get_availability(date)
    booking_date = BookingDate.find_by(date: date)
    
    if booking_date
      {
        date: date,
        lunch_available: booking_date.is_lunch_available,
        dinner_available: booking_date.is_dinner_available
      }
    else
      {
        date: date,
        lunch_available: true,
        dinner_available: true
      }
    end
  end
end