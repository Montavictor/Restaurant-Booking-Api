class Api::V1::ReservationInfosController < ApplicationController
  before_action :set_reservation_info, only: %i[ show update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  # GET /reservation_infos
  def index
    if params[:booking_date_id]
      @reservation_infos = ReservationInfo.where(booking_date_id: params[:booking_date_id])
    elsif params[:reservation_date]
      booking_date = BookingDate.find_by(date: params[:reservation_date])
      if booking_date
        @reservation_infos = booking_date.reservation_infos
      else
        @reservation_infos = []
      end
    else
      @reservation_infos = ReservationInfo.all
    end

    render json: @reservation_infos.as_json(
      include: {
        booking_date: { only: [:id, :date, :is_lunch_available, :is_dinner_available] }
      },
      except: [:created_at, :updated_at]
    ) 
  end

  # GET /reservation_infos/1
  def show
    render json: @reservation_info.as_json(
      include: {
        booking_date: { only: [:id, :date, :is_lunch_available, :is_dinner_available] }
      },
      except: [:created_at, :updated_at]
    ) 
  end
  def cancel
    
    # 1 week before 
  end
  # POST /reservation_infos or /api/v1/reservations
  def create
    payload = reservation_info_params.to_h
    amounts = ReservationInfo.calculate_amounts(payload[:number_of_guest], price: 2400)
    payment_intent = Stripe::PaymentIntent.create(
      amount: amounts[:downpayment], 
      currency: 'usd',
      payment_method_types: ['card'],
      metadata: payload
    )
    render json: {
      stripe_client_secret: payment_intent.client_secret
    }, status: :created

  end

  def confirm
    # validation for payment intent ID
    payment_intent_id = params[:payment_intent_id]
    return render json: { error: "Payment intent ID is required" }, status: :unprocessable_entity unless payment_intent_id

    payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
    return render json: { error: "Payment not successful" }, status: :unprocessable_entity unless payment_intent.status == 'succeeded'

    # check if reservation already exists
    if existing_reservation = ReservationInfo.find_by(stripe_id: payment_intent.id)
      return render json: { message: "Reservation already exists", reservation_id: existing_reservation.id }, status: :ok
    end
    
    # create new reservation  
    reservation = persists_from_payment_intent(payment_intent)  
    render json: { message: 'Reservation confirmed', reservation_id: reservation.id }, status: :created
  end

  private

  def set_reservation_info
    @reservation_info = ReservationInfo.find(params[:id])
  end

  def record_not_found
    render json: { error: "Schedule slot not found" }, status: :not_found
  end

  def handle_record_invalid(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

    # Converts Stripe payment intent to a ReservationInfo object
  def persists_from_payment_intent(payment_intent)
    attributes = {
      first_name: payment_intent.metadata['first_name'],
      last_name: payment_intent.metadata['last_name'],
      email: payment_intent.metadata['email'],
      mobile_number: payment_intent.metadata['mobile_number'],
      reservation_date: payment_intent.metadata['reservation_date'],
      meal_period: payment_intent.metadata['meal_period'],
      number_of_guest: payment_intent.metadata['number_of_guest'],
      customer_notes: payment_intent.metadata['customer_notes'],
      first_course: payment_intent.metadata['first_course'],
      second_course: payment_intent.metadata['second_course'],
      third_course: payment_intent.metadata['third_course'],
      fourth_course: payment_intent.metadata['fourth_course'],
      fifth_course: payment_intent.metadata['fifth_course'],
      sixth_course: payment_intent.metadata['sixth_course'],
      seventh_course: payment_intent.metadata['seventh_course'],
      eighth_course: payment_intent.metadata['eighth_course'],
      ninth_course: payment_intent.metadata['ninth_course'],
      stripe_id: payment_intent.id,
      status: 'confirmed',
    }

    ActiveRecord::Base.transaction do
      booking_date = BookingDate.find_or_create_by(date: attributes[:reservation_date])
      reservation_info = ReservationInfo.create!(attributes.merge(booking_date: booking_date))
      if reservation_info.meal_period == 'lunch'
        booking_date.update(is_lunch_available: false)
      elsif reservation_info.meal_period == 'dinner'
        booking_date.update(is_dinner_available: false)
      end
      reservation_info
    end
  end

    # Only allow a list of trusted parameters through.
  def reservation_info_params
    params.require(:reservation_info).permit(
      :first_name, :last_name, :email, :mobile_number, :reservation_date, :meal_period, :number_of_guest, :customer_notes, :first_course, :second_course, :third_course, :fourth_course, :fifth_course, :sixth_course, :seventh_course, :eighth_course, :ninth_course, :downpayment
    )
  end
end
