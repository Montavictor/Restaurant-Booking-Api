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

  # POST /reservation_infos or /api/v1/reservations
  def create
    ActiveRecord::Base.transaction do
      booking_date = BookingDate.find_or_create_by!(date: reservation_info_params[:reservation_date])

      @reservation_info = ReservationInfo.new(reservation_info_params)
      @reservation_info.booking_date = booking_date
      if @reservation_info.meal_period.downcase == 'lunch'
        BookingDate.where(date: booking_date.date).update(is_lunch_available: false)
      elsif @reservation_info.meal_period.downcase == 'dinner'
        BookingDate.where(date: booking_date.date).update(is_dinner_available: false)
      end
      @reservation_info.save!
      
      payment_intent = Stripe::PaymentIntent.create(
        amount: (@reservation_info.downpayment).to_i,
        currency: 'usd', metadata: {
          reservation_info_id: @reservation_info.id,
          customer_email: @reservation_info.email
        }
      )
      @reservation_info.update!(stripe_id: payment_intent.id)
      render json: {
        reservation: @reservation_info.as_json(
          include: { booking_date: { only: [:id, :date, :is_lunch_available, :is_dinner_available] } }
        ),
        stripe_client_secret: payment_intent.client_secret
      }, status: :created

    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /reservation_infos/1
  def update
    if @reservation_info.update(reservation_info_params)
      render json: @reservation_info
    else
      render json: @reservation_info.errors, status: :unprocessable_entity
    end
  end

  # DELETE /reservation_infos/1
  def destroy
    @reservation_info.destroy!
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

    # Only allow a list of trusted parameters through.
    def reservation_info_params
      params.require(:reservation_info).permit(
        :first_name, :last_name, :email, :mobile_number, :reservation_date, :meal_period, :number_of_guest, :customer_notes, :first_course, :second_course, :third_course, :fourth_course, :fifth_course, :sixth_course, :seventh_course, :eighth_course, :ninth_course
      )
    end
end
