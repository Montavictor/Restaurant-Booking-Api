class RefundService
  def initialize(reservation)
    @reservation = reservation
  end
  
  def process_refund
    return { success: true, message: "No payment to refund" } unless @reservation.stripe_id.present?
    
    begin
      refund = Stripe::Refund.create(
        payment_intent: @reservation.stripe_id,
        reason: "requested_by_customer"
      )
      
      {
        success: true,
        refund_id: refund.id,
        amount: refund.amount,
        status: refund.status
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe refund failed for reservation #{@reservation.id}: #{e.message}"
      {
        success: false,
        error: e.message,
        user_message: "Refund processing failed. Please contact support."
      }
    end
  end
end