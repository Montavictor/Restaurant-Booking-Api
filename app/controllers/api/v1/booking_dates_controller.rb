class Api::V1::BookingDatesController < ApplicationController
  before_action :set_booking, only: [:show]

  # GET /api/v1/bookings
  def index
    bookings = BookingDate.all
    render json: bookings
  end

  # POST /api/v1/bookings/upsert
  def upsert
    booking = BookingDate.find_or_initialize_by(date: booking_params[:date])

    if booking.update(booking_params)
      render json: booking, status: booking.persisted? && booking.id_previously_changed? ? :created : :ok
    else
      render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/bookings/:id
  def show
    render json: @booking
  end

  private

  def booking_params
    params.require(:booking).permit(:date, :is_lunch_available, :is_dinner_available)
  end
  
  def set_booking
    @booking = BookingDate.find(params[:id])
  end
end