class Api::V1::ReservationInfosController < ApplicationController
  before_action :set_reservation_info, only: %i[ show ]
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
        booking_date: { only: [ :id, :date, :is_lunch_available, :is_dinner_available ] }
      },
      except: [ :created_at, :updated_at ]
    )
  end

  # GET /reservation_infos/1
  def show
    render json: @reservation_info.as_json(
      include: {
        booking_date: { only: [ :id, :date, :is_lunch_available, :is_dinner_available ] }
      },
      except: [ :created_at, :updated_at ]
    )
  end

  def cancel
    token_param = params[:cancellation_token] || params.dig(:reservation_info, :cancellation_token)
    token_param = token_param.first if token_param.is_a?(Array)
    token = token_param.to_s.strip

    reservation = ReservationInfo.find_by(cancellation_token: token)
    unless reservation
      return render json: { error: "Reservation not found with provided token" },
                    status: :not_found
    end

    if reservation.status == "cancelled"
      return render json: {
                      message: "Reservation already cancelled",
                      reservation_id: reservation.id,
                      cancelled_at: reservation.updated_at
                    },
                    status: :ok
    end

    if reservation.reservation_date < Date.today + 7.days
      return render json: {
                      error: "Reservation cannot be cancelled within 7 days of the reservation date",
                      last_cancellation_date: (reservation.reservation_date - 7.days).to_s
                    },
                    status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      reservation.lock!
      reservation.update!(status: "cancelled")
      ReservationMailer.cancellation_email(reservation).deliver_now
      if reservation.stripe_id.present?
        begin
            Stripe::Refund.create(
              payment_intent: reservation.stripe_id,
              reason: "requested_by_customer"
            )
        rescue Stripe::StripeError => e
          Rails.logger.error "Stripe refund failed: #{e.message}"
        end
      end

      # Release time slot
      booking_date = reservation.booking_date
      case reservation.meal_period
      when "lunch"
        booking_date.update!(is_lunch_available: true) unless booking_date.is_lunch_available
      when "dinner"
        booking_date.update!(is_dinner_available: true) unless booking_date.is_dinner_available
      end
    end

    render json: {
      message: "Reservation cancelled successfully",
      reservation_id: reservation.id,
      cancellation_token: reservation.cancellation_token,
      refund_processed: reservation.stripe_id.present?
    }, status: :ok
  rescue => e
    Rails.logger.error "Cancellation failed: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Cancellation failed. Please try again or contact support." },
          status: :internal_server_error
  end

  # POST /reservation_infos or /api/v1/reservations
  def create
    payload = reservation_info_params.to_h
    temp_reservation = ReservationInfo.new(payload)
    temp_reservation.booking_date = BookingDate.find_or_initialize_by(date: temp_reservation.reservation_date)
    unless temp_reservation.valid?
      return render json: { errors: temp_reservation.errors.full_messages }, status: :unprocessable_entity
    end
    amounts = ReservationInfo.calculate_amounts(payload[:number_of_guest], downpayment: payload[:downpayment])
    Rails.logger.info "Calculated amounts: #{amounts.inspect}"

    payment_intent = Stripe::PaymentIntent.create(
      amount: amounts[:total],
      currency: "usd",
      payment_method_types: [ "card" ],
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
    return render json: { error: "Payment not successful" }, status: :unprocessable_entity unless payment_intent.status == "succeeded"

    # check if reservation already exists
    if existing_reservation = ReservationInfo.find_by(stripe_id: payment_intent.id)
      return render json: { message: "Reservation already exists", reservation_id: existing_reservation.id }, status: :ok
    end

    # create new reservation
    reservation = persists_from_payment_intent(payment_intent)
    render json: { message: "Reservation confirmed", reservation_id: reservation.id }, status: :created
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
      first_name: payment_intent.metadata["first_name"],
      last_name: payment_intent.metadata["last_name"],
      email: payment_intent.metadata["email"],
      mobile_number: payment_intent.metadata["mobile_number"],
      reservation_date: payment_intent.metadata["reservation_date"],
      meal_period: payment_intent.metadata["meal_period"],
      number_of_guest: payment_intent.metadata["number_of_guest"],
      customer_notes: payment_intent.metadata["customer_notes"],
      first_course: payment_intent.metadata["first_course"],
      second_course: payment_intent.metadata["second_course"],
      third_course: payment_intent.metadata["third_course"],
      fourth_course: payment_intent.metadata["fourth_course"],
      fifth_course: payment_intent.metadata["fifth_course"],
      sixth_course: payment_intent.metadata["sixth_course"],
      seventh_course: payment_intent.metadata["seventh_course"],
      eighth_course: payment_intent.metadata["eighth_course"],
      ninth_course: payment_intent.metadata["ninth_course"],
      stripe_id: payment_intent.id,
      status: "confirmed"
    }

    ActiveRecord::Base.transaction do
      booking_date = BookingDate.find_or_create_by(date: attributes[:reservation_date])
      reservation_info = ReservationInfo.create!(attributes.merge(booking_date: booking_date))
      if reservation_info.meal_period == "lunch"
        booking_date.update(is_lunch_available: false)
      elsif reservation_info.meal_period == "dinner"
        booking_date.update(is_dinner_available: false)
      end
      reservation_info
    end
  end

  # Only allow a list of trusted parameters through.
  def reservation_info_params
    params.require(:reservation_info).permit(
      :first_name, :last_name, :email, :mobile_number, :reservation_date, :meal_period, :number_of_guest, :customer_notes, :first_course, :second_course, :third_course, :fourth_course, :fifth_course, :sixth_course, :seventh_course, :eighth_course, :ninth_course, :downpayment, :cancellation_token
    )
  end
end
