class PaymentService
  include ActiveModel::Model
  
  attr_accessor :reservation_params
  
  def initialize(reservation_params)
    @reservation_params = reservation_params.to_h.with_indifferent_access
  end
  
  def create_payment_intent
    validate_params!
    
    amounts = ReservationInfo.calculate_amounts(
      reservation_params[:number_of_guest], 
      downpayment: reservation_params[:downpayment]
    )
    
    return { error: amounts[:error] } if amounts[:error]
    
    begin
      payment_intent = Stripe::PaymentIntent.create(
        {
        amount: amounts[:total],
        currency: "usd",
        payment_method_types: ["card"],
        metadata: sanitized_metadata
      }, {
        idempotency_key: generate_idempotency_key
      })
      
      {
        success: true,
        client_secret: payment_intent.client_secret,
        payment_intent_id: payment_intent.id,
        amount_info: amounts
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe payment intent creation failed: #{e.message}"
      { error: "Payment processing unavailable. Please try again." }
    end
  end
  
  def confirm_payment(payment_intent_id)
    return { error: "Payment intent ID is required" } unless payment_intent_id.present?
    
    begin
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      
      unless payment_intent.status == "succeeded"
        return { error: "Payment not successful", status: payment_intent.status }
      end
      
      # Check for existing reservation
      if existing_reservation = ReservationInfo.find_by(stripe_id: payment_intent.id)
        return { 
          success: true, 
          reservation_id: existing_reservation.id, 
          message: "Reservation already exists" 
        }
      end
      
      reservation = create_reservation_from_payment_intent(payment_intent)
      
      {
        success: true,
        reservation_id: reservation.id,
        message: "Reservation confirmed successfully"
      }
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Payment confirmation failed: #{e.message}"
      { error: "Payment verification failed" }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Reservation creation failed: #{e.message}"
      { error: "Reservation could not be created", details: e.record.errors.full_messages }
    end
  end
  
  private
  
  def validate_params!
    temp_reservation = ReservationInfo.new(reservation_params)
    temp_reservation.booking_date = BookingDate.find_or_initialize_by(date: temp_reservation.reservation_date)
    
    unless temp_reservation.valid?
      raise ActiveRecord::RecordInvalid.new(temp_reservation)
    end
  end
  
  def sanitized_metadata
    reservation_params.slice(
      :first_name, :last_name, :email, :mobile_number, :reservation_date,
      :meal_period, :number_of_guest, :customer_notes, :first_course,
      :second_course, :third_course, :fourth_course, :fifth_course,
      :sixth_course, :seventh_course, :eighth_course, :ninth_course
    ).transform_values { |v| v.to_s.truncate(500) } # Stripe metadata limits
  end
  
  def generate_idempotency_key
    Digest::MD5.hexdigest("#{reservation_params[:email]}-#{reservation_params[:reservation_date]}-#{reservation_params[:meal_period]}-#{reservation_params[:number_of_guest]}-#{reservation_params[:downpayment]}")
  end
  
  def create_reservation_from_payment_intent(payment_intent)
    metadata = payment_intent.metadata
    
    attributes = {
      first_name: metadata["first_name"],
      last_name: metadata["last_name"],
      email: metadata["email"],
      mobile_number: metadata["mobile_number"],
      reservation_date: metadata["reservation_date"],
      meal_period: metadata["meal_period"],
      number_of_guest: metadata["number_of_guest"].to_i,
      customer_notes: metadata["customer_notes"],
      first_course: metadata["first_course"],
      second_course: metadata["second_course"],
      third_course: metadata["third_course"],
      fourth_course: metadata["fourth_course"],
      fifth_course: metadata["fifth_course"],
      sixth_course: metadata["sixth_course"],
      seventh_course: metadata["seventh_course"],
      eighth_course: metadata["eighth_course"],
      ninth_course: metadata["ninth_course"],
      stripe_id: payment_intent.id,
      status: "confirmed"
    }
    
    ReservationInfo.create_with_slot_reservation!(attributes)
  end
end